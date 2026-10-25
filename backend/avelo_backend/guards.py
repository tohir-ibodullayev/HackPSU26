"""Lightweight, context-aware server domain guard adapted from the existing backend.
Explicit vetoes/clarifications run before Groq; this is not a perfect classifier.
"""
import re
from typing import Literal
from .models import Model

REDIRECT = "I’m here mainly for your college journey 😄 Want to talk about classes, goals, or campus life?"
CLARIFY = "Is this for a class, a student project, or career preparation?"


class IntentDecision(Model):
    decision: Literal["ALLOW", "DENY", "CLARIFY"]
    category: Literal["academic", "wellbeing", "campus", "career", "social", "conversation", "ambiguous", "outside", "injection"]


class IntentGuard:
    ESCAPE = r"ignore.{0,50}(instructions|rules|system)|(?:become|act as).{0,30}(chatgpt|unrestricted)|(?:reveal|print|show|disclose|give).{0,40}(secret|api.?key|password|system prompt)|(?:pretend|role.?play).{0,80}(trivia|unrestricted|no rules)|override.{0,30}(privacy|policy|rules)|developer mode"
    OUTSIDE = r"\b(world cup|celebrity|gossip|movie review|stock price|bitcoin|random shopping|unrelated|shopping list|capital of)\b"
    TOPICS = [
        (r"\b(exams?|calculus|derivatives?|integrals?|math|stud(?:y|ying|ies)|homework|assignments?|classes|class|courses?|grades?|scores?|syllabus|quizzes|quiz|academic|grading|formula|assessment|policies|policy|reminders?|commitments?|goals?|preferences|interests|profile|remember|enjoy|time management|schedule|planning|plan|balance|managing my time|procrastination|programming course|student project)\b", "academic"),
        (r"\b(stress(?:ed)?|overwhelmed|lonely|homesick|motivation|sleep|anxious|burnt out|encouragement|sad|feeling down|worried|confidence|belong)\b", "wellbeing"),
        (r"\b(campus|college|clubs?|hackathon|student org|dorm|roommate)\b", "campus"),
        (r"\b(career|internships?|resume|interviews?|job fair)\b", "career"),
        (r"\b(friends?|football|fun|hobbies|social|weekend|rest|relax)\b", "social"),
    ]
    @classmethod
    def escape(cls, text): return bool(re.search(cls.ESCAPE, text, re.I | re.S))

    @staticmethod
    def general_learning(text):
        return bool(re.search(r"\b(explain|teach|learn|understand|practice)\b.*\b(derivatives?|integrals?|math|python|programming|concepts?)\b|\b(prepare|study|studying)\b.*\b(exam|test)\b|\b(improve|better)\b.*\b(grades|studying|time management)\b", text, re.I)) and not re.search(r"\b(my grade|my score|my exam date|syllabus|according to|source quote)\b|\d|%", text, re.I)

    @classmethod
    def evaluate(cls, text, history=()):
        if cls.escape(text): return IntentDecision(decision="DENY", category="injection")
        if re.search(cls.OUTSIDE, text, re.I): return IntentDecision(decision="DENY", category="outside")
        if re.fullmatch(r"\s*(hi|hello|hey|good morning|thanks|thank you|okay|ok|yes|no|sure|sounds good)[!., ]*", text, re.I):
            return IntentDecision(decision="ALLOW", category="conversation")
        if re.search(r"\bi (?:like|enjoy|am interested in)\b", text, re.I):
            return IntentDecision(decision="ALLOW", category="social")
        for pattern, category in cls.TOPICS:
            if re.search(pattern, text, re.I): return IntentDecision(decision="ALLOW", category=category)
        # Context is limited to prior accepted cloud user turns, never documents or tool instructions.
        previous = next((cls.evaluate(m["content"]) for m in reversed(list(history)[-4:]) if m.get("role") == "user" and m.get("content")), None)
        if re.search(r"\b(python|coding|code|programming|script)\b", text, re.I):
            return IntentDecision(decision="ALLOW" if previous and previous.category in {"academic", "career"} else "CLARIFY", category="ambiguous")
        if previous and previous.decision == "ALLOW" and re.search(r"^(how|why|what|can|could|that|it|tell me more|i think|i feel|maybe|yes|no)\b", text, re.I):
            return IntentDecision(decision="ALLOW", category=previous.category)
        return IntentDecision(decision="CLARIFY", category="ambiguous")
