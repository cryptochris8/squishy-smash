"""Generate SRT for the master-with-quiz video.

Extends build_srt.py with quiz tail captions.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from build_srt import build_cues, fmt_time, emit_srt, COVER_OFFSET, SEGMENT_ENDS
from build_master_with_quiz import QUIZ, QUIZ_INTRO, Q_HOLD, A_HOLD, QUIZ_OUTRO

HOME = Path(r"C:\Users\chris")
OUT_SRT = HOME / "squishy_book2_readalong_horizontal_george_master_quiz.srt"

# Time at which the quiz starts (after cover + full source VO)
VO_END = SEGMENT_ENDS[-1] + COVER_OFFSET  # = 337.62 + 3.0 = 340.62


def build_quiz_cues(start_time: float):
    """Return list of (start, end, text) cues for the quiz tail."""
    cues = []
    t = start_time

    # Intro card
    cues.append((t, t + QUIZ_INTRO, "Quiz Time! How well do you remember the story?"))
    t += QUIZ_INTRO

    # Q/A pairs
    for i, (q, a) in enumerate(QUIZ, start=1):
        cues.append((t, t + Q_HOLD, f"Question {i}: {q}"))
        t += Q_HOLD
        cues.append((t, t + A_HOLD, f"Answer: {a}"))
        t += A_HOLD

    # Outro
    cues.append((t, t + QUIZ_OUTRO, "Thanks for reading along."))
    return cues


def main():
    main_cues = build_cues()
    quiz_cues = build_quiz_cues(VO_END)
    all_cues = main_cues + quiz_cues
    emit_srt(all_cues, OUT_SRT)
    print(f"\nQuiz tail starts at {fmt_time(VO_END)}")
    for c in quiz_cues:
        print(f"  {fmt_time(c[0])} --> {fmt_time(c[1])}  {c[2][:70]}")


if __name__ == "__main__":
    main()
