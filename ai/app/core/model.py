from abc import ABC, abstractmethod
import albumentations as A
from albumentations.pytorch import ToTensorV2
import cv2
import torch
from torch import nn
from torch.utils.data import DataLoader
from torchvision import models
from typing import List

class BaseModel(ABC):
    """Base class for all models with common functionality"""
    
    def __init__(self, num_classes, pretrained=True, version=None, freeze_base=False, dataset=None, model_name=None):
        self.num_classes = num_classes
        self.pretrained = pretrained
        self.version = version
        self.freeze_base = freeze_base
        self.dataset = dataset
        self.model_name = model_name
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        self.model = None
        self.mean = None
        self.std = None

        # hardcoded
        self.label_mapping = {
            0: "Cancer",
            1: "OPMD",
            2: "Other"
        }
        
    @classmethod
    def load_from_checkpoint(cls, path):
        """Factory method to create model from checkpoint"""
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        checkpoint = torch.load(path, map_location=device, weights_only=False)
        model = cls(
            num_classes=checkpoint['num_classes'],
            pretrained=True, # hardcoded
            version=checkpoint["model_version"],
            # augment=True, # hardcoded
            freeze_base=False, # hardcoded
            dataset=checkpoint["model_dataset"],
            model_name=checkpoint["model_name"]
            )
        model.model.load_state_dict(checkpoint['model_state_dict'])
        return model
    
    def predict_batch(self, dataloader: DataLoader) -> List[str]:
        self.model.eval()
        predictions = []
        
        with torch.no_grad():
            for images in dataloader:
                images = images.to(self.device)
                outputs = self.model(images)
                predicted_labels = torch.argmax(outputs, dim=1).cpu().numpy()
                predictions.extend([self.label_mapping[i] for i in predicted_labels])

        return predictions

class EfficientNetModel(BaseModel):
    def __init__(self, num_classes=6, pretrained=True, version="b3", freeze_base=False, dataset=None, model_name=None):
        super().__init__(
            num_classes=num_classes,
            pretrained=pretrained,
            version=version,
            freeze_base=freeze_base,
            dataset=dataset,
            model_name=model_name
            )
        """
        Initialize the EfficientNet model.
        Supported efficient Net versions:  "bo", ..., "b7"
        """

        model_fn = getattr(models, f"efficientnet_{self.version}", None)
        if not model_fn:
            raise ValueError(f"EfficientNet version '{self.version}' is not supported.")

        model_metadata = models.get_model_weights(model_fn).DEFAULT
        input_size = model_metadata.transforms().crop_size[0]
        self.mean = model_metadata.transforms().mean
        self.std = model_metadata.transforms().std

        self.weights = model_metadata
        self.model = self._load_model(model_fn=model_fn)

        self.preprocess = self._get_preprocessing_pipeline(
            input_size=input_size, 
            augment=False
        )

        self.target_layer = self._get_last_conv_layer()

    def _load_model(self, model_fn):
        """
        Load the EfficientNet model with pretrained weights.
        """

        model = model_fn(weights=self.weights if self.pretrained else None)

        if self.freeze_base:
            for param in model.features.parameters():
                param.requires_grad = False

        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(p=0.5, inplace=True),
            nn.Linear(in_features, self.num_classes),
        )
        return model.to(self.device)

    def _get_preprocessing_pipeline(self, input_size, augment=False):
        """
        Define the preprocessing steps for input images.
        """
        if augment:
            transformation = A.Compose([
            A.RandomRotate90(p=0.3),
            A.HorizontalFlip(p=0.3),  
            A.VerticalFlip(p=0.3), 
            A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.3),
            A.GaussianBlur(blur_limit=3, p=0.3),
            A.Resize(height=input_size, width=input_size, interpolation=cv2.INTER_CUBIC),
            A.Normalize(mean=self.mean, std=self.std),
            ToTensorV2()
            ])
        else:
            transformation = A.Compose([
            A.Resize(height=input_size, width=input_size, interpolation=cv2.INTER_CUBIC),
            A.Normalize(mean=self.mean, std=self.std),
            ToTensorV2()
        ])
        
        return transformation
    
    def _get_last_conv_layer(self):
        return self.model.features[-1]