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
							- fps.height
							)
			height: width
			antialiasing: true
			smooth: true

			property rect range: Qt.rect(-10, -10, 10, 10)
			property real lw: _lw.value
			property real t: 0
			property real _width: width

			property string expression: exp.text

			property bool f1: cbr.checked
			property bool f2: cbb.checked

			fragmentShader: "
varying vec2 qt_TexCoord0;

uniform vec4 range;
uniform highp float t;
uniform highp float lw;
uniform highp float _width;

uniform bool f1;
uniform bool f2;

highp float k=0.4;
highp float ep0=(range.z-range.x)*lw/_width;
highp float ep1=(range.z-range.x)*lw*k/_width;
highp float eps=1e-8;

highp float eval(highp float x, highp float y){
highp float s=sin(t*3.14159265359/60.);
highp float c=cos(t*3.14159265359/60.);
highp vec2 rt=vec2(c,s);

highp vec2 xy=vec2(x,y);
highp vec3 xyt=vec3(x,y,t);
return (%1);
}

highp float value0(highp float x, highp float y){
highp float dx, dy;
highp float v=abs(eval(x,y));
highp float s=0.;
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

highp float value1(highp float x, highp float y){
highp float v=abs(eval(x,y));
highp float s;
s=abs(eval(x-ep1,y-ep1));
s=min(s,abs(eval(x,y-ep1)));
s=min(s,abs(eval(x+ep1,y-ep1)));
s=min(s,abs(eval(x-ep1,y)));
s=min(s,abs(eval(x+ep1,y)));
s=min(s,abs(eval(x-ep1,y+ep1)));
s=min(s,abs(eval(x,y+ep1)));
s=min(s,abs(eval(x+ep1,y+ep1)));
highp float o = k/lw;
v*=o;
if (v<eps) v=eps;
if (s<v) s=v;
return 1.+o-v/s;
}

void main(){
highp float x = qt_TexCoord0.x*(range.z-range.x)+range.x;
highp float y = range.w-qt_TexCoord0.y*(range.w-range.y);
highp float u = f1?value0(x,y):1.;
highp float v = f2?value1(x,y):1.;
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
						text: "y-sin(x+t*0.1)"
						antialiasing: true
						font.pointSize: 18

						property string t
						onTextChanged: {
							t = text
							var i=t.indexOf("=")
							while (i>0) {
								if (t[i+1]!=='=') {
									t = t.substring(0, i) + '-' + t.substring(i+1)
									i +=1
								} else i+=2
								i=t.indexOf("=", i)
							}
							console.log(t)
							shader.expression = t
							shader.t = 0
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
				minimumValue: .5
				maximumValue: 9.5
				value: 1.5
			}

			Slider {
				id:fps
				width:parent.width
				minimumValue: 1
				maximumValue: 60
				value: 30
			}
		}

		Timer{
			id:timer
			interval:1000/fps.value
			onTriggered: shader.t += 1.
			running: true
			repeat: true
		}
	}
