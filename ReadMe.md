AcionSheetController
====

AcionSheetController is an iOS control for presenting a view in an iOS action sheet or alert style. You can add a custom view, representing your custom content, and add any number of buttons to represent actions related to that content. You can also forgo any custom view and simply present a number of actionable buttons.

![Picker View](https://sintraworks.github.io/ActionSheetController/Images/ActionSheetContollerSample1.png)
![Buttons, light theme](https://sintraworks.github.io/ActionSheetController/Images/ActionSheetContollerSample2.png)

![Buttons, dark theme](https://sintraworks.github.io/ActionSheetController/Images/ActionSheetContollerSample3.png)

AcionSheetController is written in **Swift** and was inspired by [RMActionController](https://github.com/CooperRS/RMActionController) by [Roland Moers](https://github.com/CooperRS). AcionSheetController differs in a number of aspects, firstly, of course, by being written in Swift, and also importantly by basing itself on **UIStackView**.
Usage
====
By default ActionSheetController doesn't contain a content view, and will only show buttons for any actions you add. To show a content view you simply set the contentView property to hold the desired view. There is generally no need to subclass ActionSheetController, although you can if you want to.

###Adding a view
Lets say you want to add a date picker:
- You instantiate a UIDatePicker
- You instantiate an action and consult the date picker in its handler, to extract the selected date.
- You set the picker as the content view of the ActionSheetController

```swift
private func datePickerSheet() -> ActionSheetController {
        let pickerView = UIDatePicker(frame: CGRectZero)

        let okAction = ActionSheetControllerAction(style: .Done, title: "OK", dismissesActionController: true) { controller in
            let date = pickerView.date
            let action = AlertAction(title: "Hurray!", style: .Default, enabled: true, isPreferredAction: true) {
                print("Dismissed!")
            }
            let alertInfo = AlertInfo(title: "Success", message: "You picked date: \(date.description)", actions: [action])
            AlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let cancelAction = ActionSheetControllerAction(style: .Cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(title: "Date Picker", message: "Pick a date for your enjoyment…", cancelAction: cancelAction, okAction: okAction)
        
        sheetController.contentView = pickerView
        
        return sheetController
    }
```
###Presenting
Presenting the controller is pretty standard:

```swift
        var sheetController = self.datePickerSheet()
        self.controller.presentViewController(sheetController, animated: true, completion: nil)
```

###Presentation Style
ActionSheetController can be presented as a popover on iPad, and it has a light and a dark theme, suitable for different context, and/or personal preference.

###Requirements

| Compile Time  | Runtime       |
| :------------ | :------------ |
| Xcode 7       | iOS 9         |
| iOS 9 SDK     |               

## License (MIT License)
Copyright (c) 2016 Antonio Nunes

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
