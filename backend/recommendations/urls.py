from django.urls import path
from .views import RecommendationDecisionView, RecommendationListView


urlpatterns = [
    path('', RecommendationListView.as_view()),
    path('<int:pk>/<str:decision>/', RecommendationDecisionView.as_view()),
]
