#!/bin/bash

NUM_PROCESSES=10
DEVICE_TYPE='gpu'
NUM_EPOCHS=10
HEATMAP_BATCH_SIZE=100
GPU_NUMBER=0

DATA_FOLDER='/kaggle/input/nyukat-breast-cancer-classifier-2/sample_data/images'
INITIAL_EXAM_LIST_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/sample_data/exam_list_before_cropping.pkl'
PATCH_MODEL_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/models/sample_patch_model.p'
IMAGE_MODEL_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/models/sample_image_model.p'
IMAGEHEATMAPS_MODEL_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/models/sample_imageheatmaps_model.p'

CROPPED_IMAGE_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/sample_output/cropped_images'
CROPPED_EXAM_LIST_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/sample_output/cropped_images/cropped_exam_list.pkl'
EXAM_LIST_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/sample_output/data.pkl'
HEATMAPS_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/sample_output/heatmaps'
IMAGE_PREDICTIONS_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/sample_output/image_predictions.csv'
IMAGEHEATMAPS_PREDICTIONS_PATH='/kaggle/input/nyukat-breast-cancer-classifier-2/sample_output/imageheatmaps_predictions.csv'
export PYTHONPATH=$(pwd):$PYTHONPATH

echo 'Stage 1: Crop Mammograms'
python3 /kaggle/input/nyukat-breast-cancer-classifier-2/src/cropping/crop_mammogram.py \
    --input-data-folder $DATA_FOLDER \
    --output-data-folder $CROPPED_IMAGE_PATH \
    --exam-list-path $INITIAL_EXAM_LIST_PATH  \
    --cropped-exam-list-path $CROPPED_EXAM_LIST_PATH  \
    --num-processes $NUM_PROCESSES

echo 'Stage 2: Extract Centers'
python3 /kaggle/input/nyukat-breast-cancer-classifier-2/src/optimal_centers/get_optimal_centers.py \
    --cropped-exam-list-path $CROPPED_EXAM_LIST_PATH \
    --data-prefix $CROPPED_IMAGE_PATH \
    --output-exam-list-path $EXAM_LIST_PATH \
    --num-processes $NUM_PROCESSES

echo 'Stage 3: Generate Heatmaps'
python3 /kaggle/input/nyukat-breast-cancer-classifier-2/src/heatmaps/run_producer.py \
    --model-path $PATCH_MODEL_PATH \
    --data-path $EXAM_LIST_PATH \
    --image-path $CROPPED_IMAGE_PATH \
    --batch-size $HEATMAP_BATCH_SIZE \
    --output-heatmap-path $HEATMAPS_PATH \
    --device-type $DEVICE_TYPE \
    --gpu-number $GPU_NUMBER

echo 'Stage 4a: Run Classifier (Image)'
python3 /kaggle/input/nyukat-breast-cancer-classifier-2/src/modeling/run_model.py \
    --model-path $IMAGE_MODEL_PATH \
    --data-path $EXAM_LIST_PATH \
    --image-path $CROPPED_IMAGE_PATH \
    --output-path $IMAGE_PREDICTIONS_PATH \
    --use-augmentation \
    --num-epochs $NUM_EPOCHS \
    --device-type $DEVICE_TYPE \
    --gpu-number $GPU_NUMBER

echo 'Stage 4b: Run Classifier (Image+Heatmaps)'
python3 /kaggle/input/nyukat-breast-cancer-classifier-2/src/modeling/run_model.py \
    --model-path $IMAGEHEATMAPS_MODEL_PATH \
    --data-path $EXAM_LIST_PATH \
    --image-path $CROPPED_IMAGE_PATH \
    --output-path $IMAGEHEATMAPS_PREDICTIONS_PATH \
    --use-heatmaps \
    --heatmaps-path $HEATMAPS_PATH \
    --use-augmentation \
    --num-epochs $NUM_EPOCHS \
    --device-type $DEVICE_TYPE \
    --gpu-number $GPU_NUMBER
