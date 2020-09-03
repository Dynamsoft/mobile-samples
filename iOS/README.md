# Mobile Samples iOS

These samples show how to use Dynamsoft Barcode Reader SDK to perform simple or more advanced settings and implement barcode scanning on the ios platform.

To learn more about Dynamsoft Barcode Reader, please visit http://www.dynamsoft.com/Products/Dynamic-Barcode-Reader.aspx.

## License

You can request for a free trial license online. [Get a trial license >](https://www.dynamsoft.com/CustomerPortal/Portal/Triallicense.aspx)

Without a valid license, the SDK can work but will not return a full result.

## Dependencies
```bash
Recommend Xcode 10 or more. iOS 9.0
```

## How to Run the Samples

Unzip `DynamsoftBarcodeReader.framework.zip` in the `mobile-demos/iOS/Frameworks` to the current directory, and then you can run samples.

### BasicRuntimeSettings

The sample of `BasicRuntimeSettings` shows common runtime settings.

### DecodeDPM

The sample of `DecodeDPM` shows how to decode using DPM mode.Set furtherModes.dpmCodeReadingModes: `EnumDPMCodeReadingModeGeneral`, reads DPM code using the general algorithm.
When this mode is set, the library will automatically add EnumLocalizationModeStatisticsMarks to EnumLocalizationMode and add a EnumBinarizationModeLocalBlock to EnumBinarizationMode which is with arguments: BlockSizeX=0, BlockSizeY=0, EnableFillBinaryVacancy=0, ImagePreprocessingModesIndex=1, ThreshValueCoefficient=15 if you dosen't set them.

Set barcodeFormatIds: `EnumBarcodeFormat.DATAMATRIX`.

### DecodeVideoFrame

The sample of `DecodeVideoFrame` shows how to set and decode video frames.Involving how to call `startFrameDecodingEx` , `setDBRTextResultDelegate` and  `setDBRErrorDelegate`.

### FastReadBarcode

The sample of `FastReadBarcode` shows what kind of settings make decoding faster. `deblurLevel`: lower will be faster, for a blurry image, you may set the property to a larger value. The higher the value set, the more effort the library will spend to decode images. However, this could slow down the recognition process. `ExpectedBarcodesCount`:less will be faster, 
0: unknown barcode count. The library will try to find at least one barcode. 
1: try to find one barcode. If one barcode is found, the library will stop the localization process and perform barcode decoding. 
n: try to find n barcodes. If the library only finds m (m<n) barcodes, it will try different algorithms till n barcodes are found or all algorithms are tried.
priority of `LocalizationModes`decides the time spent, `EnumLocalizationModeScanDirectly`: localizes barcodes quickly.

### ReadBarcodeConfidence

The sample of `ReadBarcodeConfidence` shows common runtime settings related to confidence. `minResultConfidence` means the minimum confidence of the barcode can be decoded, which filters out low-confidence codes.

### ReadBarcodeFromRegion

The sample of `ReadBarcodeFromRegion` shows common runtime settings related to region. Set the coordinate or percentage of the region, a smaller area can reduce decode time and increase recognition accuracy.
`regionMeasuredByPercentage`: when it's set to 1, the values of Top, Left, Right, Bottom indicate the percentage (from 0 to 100); otherwise, they refer to the coordinates.
0: not by percentage.
1: by percentage. 

### SeniorRuntimeSettings

The sample of `SeniorRuntimeSettings` shows senior runtime settings by `setModeArgument()`. Set the optional argument for a specified mode in Modes parameters.
`modeName` : The mode parameter name to set argument.
`index` : The array index of mode parameter to indicate a specific mode.
`argumentName` : The name of the argument to set.
`argumentValue` : The value of the argument to set.

### SimpleBarcodeReader

The sample of `SimpleBarcodeReader` shows common runtime settings related to general scan.
Set `barcodeFormatIds`: `EnumBarcodeFormat.ONED`, `EnumBarcodeFormat.PDF417` ,`EnumBarcodeFormat.QRCODE`, `EnumBarcodeFormat.DATAMATRIX`. Setting only part of the required barcodeFormat can reduce decoding time.
`ExpectedBarcodesCount`: 512. try to find 512 barcodes. If the library only finds m (m<512) barcodes, it will try different algorithms till 512 barcodes are found or all algorithms are tried.
`ScaleDownThreshold` : 10000 , If the shorter edge size is larger than the given value, the library calculates the required height and width of the barcode image and shrinks the image to that size before localization; otherwise, it performs barcode localization on the original image.
`LocalizationModes` : `EnumLocalizationModeScanDirectly`, `EnumLocalizationModeConnectedBlocks`.
