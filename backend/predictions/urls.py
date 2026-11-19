from django.urls import path
from .views import (
    DiseasePredictionView,
    PredictionHistoryView,
    YieldPredictionView,
)


urlpatterns = [
    path('disease/', DiseasePredictionView.as_view()),
    path('yield/', YieldPredictionView.as_view()),
    path('history/', PredictionHistoryView.as_view()),
]
