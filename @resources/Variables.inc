[Variables]
; The color of the circular borders around each ring, and the lines that divide the button sections
; Best kept at the default (255,255,255)
BorderColor=255,255,255

; RingCount is how many rings with "buttons" the launcher has
; RingCenterSize - the size of the image display in the center of the skin

; Ring[n].Count - the number of button sections in the specified ring, where [n] is a number in the range 1-RingCount
; Ring[n].Size - the size of the specified ring, where [n] is a number in the range 1-RingCount
; Ring[n].Offset - extra rotation of a ring in radians (#2PI# is 360 degrees, that means that #2PI#/16 is a sixteenth of 360 degrees or 22.5 degrees)
RingCount=2
RingCenterSize=60

Ring1.Count=8
Ring1.Size=40

Ring2.Count=8
Ring2.Size=50
Ring2.Offset=(#2PI#/16)



; Syntax: [Ring#]s[Section#][Option]
; Valid options are Bang, Image and Color
; Hover over a section on the skin and it'll tell you what that section is named

; For more information on the Bang option, see https://docs.rainmeter.net/manual/bangs/
; For more Information on the Color option, see https://docs.rainmeter.net/manual/skins/option-types/#Color

; Due to a bug in Rainmeter, your images might end up with jaggy edges. You can avoid this bug by resizing your images to (RingCenterSize*2 + 2)
; That would be (60*2+2 = 122) with the default images

1s1Bang=["C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"]
1s1Image=chrome.png
1s1Color=76,139,245

1s2Bang=["C:\Program Files (x86)\Mozilla Firefox\firefox.exe"]
1s2Image=firefox.png
1s2Color=240,150,96

1s3Bang=["C:\Program Files (x86)\Steam\steam.exe"]
1s3Image=steam.png
1s3Color=81,81,81

1s4Bang=["C:\Program Files (x86)\Skype\Phone\Skype.exe"]
1s4Image=skype.png
1s4Color=81C3E5

1s5Bang=["http://www.reddit.com"]
1s5Image=reddit.png
1s5Color=A2DFF9

1s6Bang=["https://imgur.com/"]
1s6Image=imgur.png
1s6Color=ABF8B2

1s7Bang=["http://www.4chan.org"]
1s7Image=4chan.png
1s7Color=8ACAA7

1s8Bang=["http://www.youtube.com"]
1s8Image=youtube.png
1s8Color=FF7171


2s1Bang=["minecraft.exe"]
2s1Image=minecraft.png
2s1Color=92DD9B

