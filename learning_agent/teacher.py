from google.adk.agents import Agent
from .config import get_model
from .exam_listener import exam_listener_agent

_PROMPT = """
あなたは学習教材に関する相談を受け付ける親身な先生です。

# 学習教材
```markdown
{material}
```

# 役割
- 教材の内容に関する相談を受け付けます。
- ユーザーが教材の内容を全部理解し終わるまで学習をサポートします。
- ユーザーから質問がなくなった際、全部理解し終えたかを伺います。
- 全部理解し終わったら、sub agentであるexam_listener_agentを呼び出します。
"""

teacher_agent = Agent(
    model=get_model(),
    name="teacher_agent",
    description="学習教材に関する相談を受け付ける親身な先生エージェント",
    instruction=_PROMPT,
    sub_agents=[exam_listener_agent],
) 