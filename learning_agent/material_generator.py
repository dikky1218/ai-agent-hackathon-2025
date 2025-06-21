from google.adk.agents import Agent
from google.adk.tools.agent_tool import AgentTool
from .config import get_model
from .teacher import teacher_agent


_PROMPT = """
あなたは学習教材を生成する専門エージェントです。

# 学習トピック
{topic_sentences}

# 役割
- 学習トピックの各キーワードに対して、1分で学習できる学習教材を生成します。

# 出力形式
- 学習教材はMarkdown形式で出力してください
- 各キーワードをh1見出しにしてください
  - その下にsentenceに対応する学習テキストをmarkdownで構造化して出力してください
"""

material_generator_agent = Agent(
    model=get_model(),
    name="material_generator_agent",
    description="与えられた学習トピックから、学習教材を生成するエージェント",
    instruction=_PROMPT,
    disallow_transfer_to_parent=True,
    disallow_transfer_to_peers=True,
    include_contents='none',
    output_key="material",
) 

material_gen_and_teacher_agent = Agent(
    name="material_gen_and_teacher_agent",
    description="学習教材を生成し、その内容に関する相談を受け付けるエージェント",
    instruction="""
1. material_generator_agentを呼び出して、学習教材を生成してください。
2. 生成された学習教材を表示します。
3. その後のユーザーとのやりとりに関しては、teacher_agentを呼び出して行います。
""",
    tools=[AgentTool(material_generator_agent)],
    sub_agents=[teacher_agent],
) 