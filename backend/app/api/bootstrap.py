from app.api.dbmanager import DbManager
from app.api.aiqueue import AIQueue

dbmanager = DbManager(aiqueue=None)
aiqueue = AIQueue(dbmanager=dbmanager)
dbmanager.aiqueue = aiqueue