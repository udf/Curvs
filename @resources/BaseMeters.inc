; Note: This file contains meters that appear below the borders, until I figure out how to set the zpos on a meter, this is file stays
[CenterText]
Meter=String
W=(sqrt(2 * (#RingCenterSize#**2)))
H=(sqrt(2 * (#RingCenterSize#**2)))
X=(#CURRENTCONFIGWIDTH#/2)
Y=(#CURRENTCONFIGHEIGHT#/2)
DynamicVariables=1
AntiAlias=1
FontFace=Roboto
FontColor=#BorderColor#
StringAlign=CenterCenter
StringEffect=SHADOW
FontEffectColor=0,0,0,100
ClipString=1

; TODO: Figure out how to actually AntiAlias the image when using a resized MaskImage
[Center]
Meter=Image
ImagePath=#ImagePath#
ImageName=
MaskImageName=mask.png
MaskImagePath=#@#
W=(#RingCenterSize# * 2 + 2)
H=(#RingCenterSize# * 2 + 2)
X=(#CURRENTCONFIGWIDTH# / 2 - (#RingCenterSize# + 1))
Y=(#CURRENTCONFIGHEIGHT# / 2 - (#RingCenterSize# + 1))
DynamicVariables=1
AntiAlias=1

[CenterFade]
Meter=Image
ImagePath=#ImagePath#
ImageName=
MaskImageName=mask.png
MaskImagePath=#@#
W=(#RingCenterSize# * 2 + 2)
H=(#RingCenterSize# * 2 + 2)
X=(#CURRENTCONFIGWIDTH# / 2 - (#RingCenterSize# + 1))
Y=(#CURRENTCONFIGHEIGHT# / 2 - (#RingCenterSize# + 1))
DynamicVariables=1
AntiAlias=1
