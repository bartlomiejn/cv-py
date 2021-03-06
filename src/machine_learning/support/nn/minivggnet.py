from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D
from tensorflow.keras.layers import BatchNormalization
from tensorflow.keras.layers import Dense, Activation, Flatten, Dropout
from tensorflow.keras import backend as K


class MiniVGGNet:
    @staticmethod
    def build(width, height, depth, classes, batch_norm=True):
        model = Sequential()
        input_shape = (height, width, depth)
        chan_dim = -1

        if K.image_data_format() == "channels_first":
            input_shape = (depth, height, width)
            chan_dim = 1

        # 1st Conv => Relu => Conv => Relu => Pool

        model.add(Conv2D(32, (3, 3), padding="same", input_shape=input_shape))
        model.add(Activation("relu"))
        if batch_norm:
            model.add(BatchNormalization(axis=chan_dim))

        model.add(Conv2D(32, (3, 3), padding="same"))
        model.add(Activation("relu"))
        if batch_norm:
            model.add(BatchNormalization(axis=chan_dim))

        model.add(MaxPooling2D(pool_size=(2, 2)))
        model.add(Dropout(0.25))

        # 2nd Conv => Relu => Conv => Relu => Pool

        model.add(Conv2D(64, (3, 3), padding="same", input_shape=input_shape))
        model.add(Activation("relu"))
        if batch_norm:
            model.add(BatchNormalization(axis=chan_dim))

        model.add(Conv2D(64, (3, 3), padding="same"))
        model.add(Activation("relu"))
        if batch_norm:
            model.add(BatchNormalization(axis=chan_dim))

        model.add(MaxPooling2D(pool_size=(2, 2)))
        model.add(Dropout(0.25))

        # FC => Relu

        model.add(Flatten())
        model.add(Dense(512))
        model.add(Activation("relu"))
        if batch_norm:
            model.add(BatchNormalization())

        model.add(Dropout(0.5))

        # Softmax

        model.add(Dense(classes))
        model.add(Activation("softmax"))

        return model

