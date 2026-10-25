"""Allowlisted synthetic UI-v2 wire contract; no document/profile/free-form record fields."""
from datetime import date
from typing import Literal
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field, model_validator

class Model(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)

CourseID = Literal["calculus", "programming"]
TARGETS = {"A":93.0,"A−":90.0,"B+":87.0,"B":83.0,"C":73.0}

class Summary(Model):
    target: float
    completed_weight: float = Field(ge=0, le=100)
    earned: float = Field(ge=0, le=100)
    remaining_weight: float = Field(ge=0, le=100)
    valid: Literal[True]
    recorded_average: float | None = Field(ge=0, le=100)
    maximum_possible: float | None = Field(ge=0, le=100)
    required_remaining: float | None = Field(ge=0)
    at_risk: bool

class DemoCourse(Model):
    id: CourseID
    target: Literal["A","A−","B+","B","C"]
    midterm: float | None = Field(ge=0, le=100)
    final: float | None = Field(ge=0, le=100)
    coursework: float | None = Field(ge=0, le=100)
    summary: Summary

    @model_validator(mode="after")
    def validate_local_calculation(self):
        # Integrity check only; the existing Swift calculator remains the UI arithmetic source.
        pairs=[(self.midterm,30),(self.final,40),(self.coursework,30)]
        weight=sum(w for score,w in pairs if score is not None)
        earned=sum(score*w/100 for score,w in pairs if score is not None)
        remaining=100-weight; target=TARGETS[self.target]
        expected={"target":target,"completed_weight":weight,"earned":earned,"remaining_weight":remaining,
            "recorded_average":earned/weight*100 if weight else None,
            "maximum_possible":earned+remaining if weight else None,
            "required_remaining":max(0,(target-earned)/remaining*100) if weight and remaining else None}
        for name,value in expected.items():
            actual=getattr(self.summary,name)
            if (actual is None)!=(value is None) or (actual is not None and abs(actual-value)>0.00001):
                raise ValueError("Local grade summary is inconsistent with the synthetic scores")
        risk=weight>0 and earned+remaining+0.000001<target
        if self.summary.at_risk != risk: raise ValueError("Inconsistent local grade status")
        return self

class ProactiveContext(Model):
    kind: Literal["grade_risk", "exam"]
    course_id: CourseID

class DemoContext(Model):
    scope: Literal["synthetic_ui_v2"]
    fixture_day: date
    courses: list[DemoCourse] = Field(min_length=1,max_length=2)
    interests: list[Literal["AI","hackathons","football","sports","clubs","art","career","technology","music","social"]] = Field(max_length=10)
    proactive: ProactiveContext | None = None
    @model_validator(mode="after")
    def unique_courses(self):
        if len({c.id for c in self.courses}) != len(self.courses): raise ValueError("Duplicate demo course")
        if self.proactive and self.proactive.course_id not in {c.id for c in self.courses}: raise ValueError("Unknown proactive course")
        return self

class ChatRequest(Model):
    conversation_id: UUID
    request_id: UUID
    message: str = Field(min_length=1,max_length=1500)
    context: DemoContext
