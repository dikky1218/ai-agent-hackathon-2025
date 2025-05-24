from google.adk.agents import Agent
from .config import get_model


_PROMPT = """
あなたはユーザーのプレゼンテーションを聞き役としてサポートするエージェントです。

# 役割
- ユーザーが学習した内容のプレゼンテーションを聞きます。
- 途中で口を挟まず、最後まで集中して聞きます。
- プレゼンテーションが終わったら、評価をするために exam_evaluator_agent を呼び出します。

"""

exam_listener_agent = Agent(
    model=get_model(),
    name="exam_listener_agent",
    description="ユーザーのプレゼンテーションの聞き役エージェント",
    instruction=_PROMPT,
) 