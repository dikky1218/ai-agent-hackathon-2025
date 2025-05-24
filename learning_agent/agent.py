"""学習教材生成AIエージェント"""

from google.adk.agents import SequentialAgent
from .config import get_model
from .material_generator import material_generator_agent
from .topic_hearing import topic_hearing_agent

from google.adk.tools import agent_tool

# メイン学習教材生成エージェント
root_agent = SequentialAgent(
    name="learning_material_agent",
    # model=get_model(),
    # description="学習キーワードから要点スライドを生成するエージェント",
    # instruction="""
    # あなたは学習教材作成の専門エージェントです。
    
    # **対応手順:**
    # 1. topic_hearing_agentを使用してユーザーから学習トピックを聞き出す。
    # 2. 決定した学習トピックから教材をgenerate_learning_materialで生成
    # 3. エラーが発生した場合は適切なエラーメッセージを表示
    # """,
    sub_agents=[topic_hearing_agent],
) 