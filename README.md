# YYImagePicker

A Custom ImagePicker Code with `SwiftUI`.

# Author

Thanks for [Kavsoft](https://www.youtube.com/c/Kavsoft)!!!😁

# ScreenShot

![Preview](https://github.com/ChuanqingYang/YYImagePicker/blob/main/screenshot.png)

# Usage

``` swift
VStack {

}
.popupImagePickerView(show: $showImagePicker) { assets in

}
```

You can use the method  `func handle(assets:[PHAsset],completion:@escaping ([UIImage])->())` declared in `PopupImagePickerViewModel` to handle
`PHAsset` to useful `UIImage` which is syncronized

