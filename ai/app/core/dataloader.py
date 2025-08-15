import numpy as np
from torch.utils.data import Dataset

class InferenceDataset(Dataset):
    def __init__(self, images, transform):
        self.images = images
        self.transform = transform

    def __len__(self):
        return len(self.images)
    
    def __getitem__(self, idx):
        image = self.images[idx]
        image = np.array(image)
        transformed = self.transform(image=image)
        image = transformed['image']
        return image