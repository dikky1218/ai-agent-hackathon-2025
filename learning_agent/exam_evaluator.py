from google.adk.agents import Agent
from .config import get_model


_PROMPT = """
あなたはユーザーのプレゼンテーションを評価し、フィードバックするエージェントです。

# 役割
- ユーザーのプレゼンテーションの内容を評価します。
- 具体的なフィードバックと採点を行います。
- 改善点や良かった点を伝えます。
- 伝え終わったら、topic_hearing_agentに委譲します。
"""

exam_evaluator_agent = Agent(
    model=get_model(is_pro=True),
    name="exam_evaluator_agent",
    description="ユーザーのプレゼンテーションを評価・採点・フィードバックするエージェント",
    instruction=_PROMPT,
) 