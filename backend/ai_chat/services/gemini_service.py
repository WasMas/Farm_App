
import base64
from io import BytesIO

from django.conf import settings
from google import genai
from PIL import Image


SYSTEM_INSTRUCTION = """
You are the agricultural assistant for Farm_App.

YOUR ROLE:
Help users with farming, agriculture, crops, plants,
soil, irrigation, fertilizers, pests and plant diseases.

TOPIC RESTRICTION:
Only answer questions related to:
- Farming and agriculture
- Plants and crops
- Plant health and diseases
- Soil and fertilizers
- Irrigation and watering
- Pests affecting crops
- Gardening and agricultural practices

For unrelated questions, politely explain that you
are the Farm_App agricultural assistant and can only
help with farming and plants.

IMAGE ANALYSIS:
When a user sends a plant photograph:
- Describe what is visibly present.
- Identify yellow leaves, brown spots, wilting,
  discoloration or possible insect damage.
- Explain possible causes without claiming certainty.
- Suggest practical next steps.
- Ask for additional information when necessary.

Never claim that a photograph alone proves a disease.
Different conditions can produce similar symptoms.

RESPONSE STYLE:
- Be friendly and helpful.
- Use simple language.
- Organize longer answers into short sections.
- Give practical advice.
- Do not invent facts about the user's farm.
- Admit when you are uncertain.
- Don't give long paragraphs but simple and clear explinations.

You are an assistant, not a replacement for a
qualified agricultural specialist.
"""


def generate_gemini_reply(history, user_message):
    """
    Generate an agricultural response using Gemini's
    Interactions API.
    """

    if not settings.GEMINI_API_KEY:
        raise RuntimeError(
            "GEMINI_API_KEY is not configured."
        )

    # Build conversation context from PostgreSQL.
    history_text = []

    for message in history:
        if message.sender == "user":
            role = "User"
        else:
            role = "Assistant"

        content = message.content or ""

        if message.image:
            content += (
                "\n[This earlier message contained an image. "
                "The image itself is not included here.]"
            )

        if content.strip():
            history_text.append(f"{role}: {content}")

    prompt = ""

    if history_text:
        prompt += (
            "Previous conversation:\n"
            + "\n\n".join(history_text)
            + "\n\n"
        )

    prompt += (
        "Current user message:\n"
        + (user_message.content or
           "Please analyze the attached plant photograph.")
    )

    input_parts = [
        {
            "type": "text",
            "text": prompt,
        }
    ]

    # Attach the current image if one was uploaded.
    if user_message.image:
        user_message.image.open("rb")

        try:
            image_bytes = user_message.image.read()
        finally:
            user_message.image.close()

        with Image.open(BytesIO(image_bytes)) as image:
            image_format = image.format

        mime_types = {
            "JPEG": "image/jpeg",
            "PNG": "image/png",
            "WEBP": "image/webp",
        }

        mime_type = mime_types.get(image_format)

        if not mime_type:
            raise ValueError("Unsupported image format.")

        image_base64 = base64.b64encode(
            image_bytes
        ).decode("utf-8")

        input_parts.append({
            "type": "image",
            "data": image_base64,
            "mime_type": mime_type,
        })

    # Create Gemini client.
    client = genai.Client(
        api_key=settings.GEMINI_API_KEY
    )

    try:
        interaction = client.interactions.create(
            model=settings.GEMINI_MODEL,
            input=input_parts,
            system_instruction=SYSTEM_INSTRUCTION,
            generation_config={
                "temperature": 0.4,
                "max_output_tokens": 800,
            },
            # PostgreSQL is our chat-history database.
            # Avoid storing a second copy of the interaction
            # in Google's server-side interaction history.
            store=False,
        )

        answer = interaction.output_text

        if not answer:
            raise RuntimeError(
                "Gemini returned an empty response."
            )

        return answer.strip()

    finally:
        client.close()
