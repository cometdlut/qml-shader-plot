import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 1.2

Window {
	width: 512
	height: 512+50
	title: "Plot"
	visible: true

	Column {
		id: column1
		anchors.rightMargin: 6
		anchors.leftMargin: 6
		anchors.bottomMargin: 6
		anchors.topMargin: 6
		spacing: 6
		anchors.fill: parent

		ShaderEffect {
			id: shader
			//			anchors.right: parent.right
			//			anchors.rightMargin: 0
			//			anchors.left: parent.left
			//			anchors.leftMargin: 0
			//			height:parent.height-input.height-parent.spacing
			width: Math.min(parent.width,
							parent.height - parent.spacing
							 - input.height
							 - _lw.height
							)
			height: width
			antialiasing: true
			smooth: true

			property rect range: Qt.rect(-5, -5, 5, 5)
			property real lw: _lw.value
			property real _width: width

			property string expression: exp.text

			property bool f1: cbr.checked
			property bool f2: cbb.checked

			fragmentShader: "
varying vec2 qt_TexCoord0;

uniform vec4 range;
uniform float lw;
uniform float _width;

uniform bool f1;
uniform bool f2;

float ep0=(range.z-range.x)*lw/_width;
float ep1=(range.z-range.x)*lw/2./_width;
float eps=1e-8;

float eval(float x, float y){
return (%1);
}

float value0(float x, float y){
float dx, dy;
float v=abs(eval(x,y));
float s=0.;
for (dx=-ep0;dx<=ep0;dx+=ep0){
for (dy=-ep0;dy<=ep0;dy+=ep0){
s+=abs(eval(x+dx,y+dy));
}
}
s-=v;
if (v<eps) v=eps;
if (s<v*8.) s=v*8.;
return v*8./s;
}

float value1(float x, float y){
float v=abs(eval(x,y));
float s;
s=abs(eval(x-ep1,y-ep1));
s=min(s,abs(eval(x,y-ep1)));
s=min(s,abs(eval(x+ep1,y-ep1)));
s=min(s,abs(eval(x-ep1,y)));
s=min(s,abs(eval(x+ep1,y)));
s=min(s,abs(eval(x-ep1,y+ep1)));
s=min(s,abs(eval(x,y+ep1)));
s=min(s,abs(eval(x+ep1,y+ep1)));
float o = 0.5/lw;
v*=o;
if (v<eps) v=eps;
if (s<v) s=v;
return 1.+o-v/s;
}

void main(){
float x = qt_TexCoord0.x*(range.z-range.x)+range.x;
float y = range.w-qt_TexCoord0.y*(range.w-range.y);
float u = f1?value0(x,y):1.;
float v = f2?value1(x,y):1.;
gl_FragColor = vec4(v,u*v,u,1.);
}
".arg(expression)
		}

			Row {
				spacing:6
				Rectangle {
					id: input
					border.color: "red"
					height: exp.height + 2
					width: parent.parent.width-cbr.width-cbb.width-parent.spacing*2

					TextEdit {
						id: exp
						anchors.right: parent.right
						anchors.rightMargin: 2
						anchors.left: parent.left
						anchors.leftMargin: 2
						y: 2
						text: "y-sin(x)"
						antialiasing: true
						font.pointSize: 18
						onTextChanged: {
							shader.expression = text.replace("=", '-')
							console.log(shader.expression)
						}
					}
				}
				CheckBox {
					id: cbr
					anchors.verticalCenter: parent.verticalCenter
					text: "red"
					checked: true
				}
				CheckBox {
					id: cbb
					anchors.verticalCenter: parent.verticalCenter
					text: "blue"
					checked: true
				}
			}

			Slider {
				id:_lw
				width:parent.width
				minimumValue: 0.5
				maximumValue: 9.
				value: 1.
			}
		}
	}
