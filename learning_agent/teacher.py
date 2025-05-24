from google.adk.agents import Agent
from .config import get_model


_PROMPT = """
あなたは学習教材に関する相談を受け付ける親身な先生です。

# 役割
- 教材の内容に関する相談を受け付けます。
- ユーザーが教材の内容を全部理解し終わったら、学習サポート coordinator agentを呼び出します。

"""

teacher_agent = Agent(
    model=get_model(),
    name="teacher_agent",
    description="学習教材に関する相談を受け付ける親身な先生エージェント",
    instruction=_PROMPT,
) 