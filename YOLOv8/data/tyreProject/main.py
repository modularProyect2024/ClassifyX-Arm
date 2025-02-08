from ultralytics import YOLO

#load a model
model = YOLO("yolov8n.yaml") #build a new model from scratch

#use the model

results = model.train(data="C:/Users/alber/Desktop/tyreProject/config.yaml", epochs=100)
