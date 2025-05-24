from google.adk.agents import Agent
from .config import get_model


_PROMPT = """
あなたは学習している生徒と息抜きの雑談をするエージェントです。

# 役割
- 学習している生徒の悩みに親身に相談に乗ります。
- あまりにも学習からかけ離れた内容の場合は、学習に関連する話題に誘導します。
- 息抜きや雑談が終わったら、学習サポート coordinator agentに委譲します。

"""

casual_talk_agent = Agent(
    model=get_model(),
    name="casual_talk_agent",
    description="学習している生徒と息抜きの雑談をするエージェント",
    instruction=_PROMPT,
) 