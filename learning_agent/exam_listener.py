from google.adk.agents import Agent
from .config import get_model
from .exam_evaluator import exam_evaluator_agent

_PROMPT = """
あなたはユーザーの学習内容の理解度を図るためのプレゼンテーションの聞き役としてサポートするエージェントです。

# 役割
- まず、ユーザーが学習を行ったことに対して褒めます。
- 加えて、より学習を定着させるために、ユーザーにプレゼン行ってもらい学習内容を説明してもらいます。
  - 学習におけるプレゼンの理由やメリットを軽く説明します
  - ユーザーにプレゼンをするかどうかを確認します
- ユーザーがプレゼンを始めたら、聞き役に徹します。
- 途中で口を挟まず、最後まで集中して聞きます。
- ユーザーがプレゼンを終わったら、exam_evaluator_agent を呼び出します。

# プレゼンを行わせる理由
- 学習内容を定着させるためには、学習内容を説明することが重要なため。
"""

exam_listener_agent = Agent(
    model=get_model(),
    name="exam_listener_agent",
    description="ユーザーの学習内容の理解度を図るためのプレゼンテーションの聞き役エージェント",
    instruction=_PROMPT,
    sub_agents=[exam_evaluator_agent],
) 