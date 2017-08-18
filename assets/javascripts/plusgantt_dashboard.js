/* Redmine - project management software
   Copyright (C) 2006-2016  Jean-Philippe Lang */

var draw_progress = null;
var draw_top;
var draw_right;
var draw_left;

function setDrawArea() {
  draw_top   = $("#progress_draw_area").position().top;
  draw_right = $("#progress_draw_area").width();
  draw_left  = $("#progress_draw_area").position().left;
}

function drawProgressHandler(innerText, arc, color_line) {
	var folder = document.getElementById('progress_draw_area');
	if(draw_progress != null)
		draw_progress.clear();
	else
		draw_progress = Raphael(folder);
	setDrawArea();
	drawCircleProgress(innerText, arc, color_line);
}

function drawCircleProgress(innerText, progress, color_line) {
	x = 90;
	y = 90;
	r = 80;
	stroke_width = 9
	
	var backCircle = draw_progress.path(getCircletoPath(x, y, r));
	backCircle.attr({"fill": "#dddddd"});
	
	var circleDrawnasPath = draw_progress.path(getCircletoPath(x, y, r));
	circleDrawnasPath.attr({"stroke": "#eeeeee", "stroke-width": stroke_width - 5});
	
	draw_progress.customAttributes.filledArc = function(e,t,n,r,i,s){var o=360;if(o==i){i-=.001}i+=s;var u=(90-s)*Math.PI/180,a=e+n*Math.cos(u),f=t-n*Math.sin(u),l=e+(n-r)*Math.cos(u),c=t-(n-r)*Math.sin(u);var h=(90-i)*Math.PI/180,p=e+n*Math.cos(h),d=t-n*Math.sin(h),v=e+(n-r)*Math.cos(h),m=t-(n-r)*Math.sin(h);return{path:[["M",l,c],["L",a,f],["A",n,n,0,+(i>180+s),1,p,d],["L",v,m],["A",n-r,n-r,1,+(i>180+s),0,l,c]]}};
	
	var ratio = progress/100;
	var degrees = 360 * ratio;
	var rotation = 180;
	draw_progress.path().attr( { filledArc: [x,y,r+2,stroke_width,degrees,rotation], fill: color_line, stroke: color_line} );
	
	var textDrawnasPath = draw_progress.text(x - 20, y, innerText).attr({fill:'black', 'font-size':20, 'stroke-width':12,'text-anchor':'start' });
}

function arcpath(x, y, r, ratio)
{
    if ( ratio >= 1.0 ) return draw_progress.circle(x, y, r );
    var degrees = 360 * ratio;  //  we use this to determine whether to use the large-sweep-flag or not
    var radians = ( Math.PI * 2 * ratio ) - Math.PI / 2;    //  this is actually the angle of the terminal point on the circle's circumference -- up is Math.PI / 2, so we need to subtract that out.
    var pathparts = 
    [
        "M" + x + "," + y,
        "v" + ( 0 - r ),
        //"A" + r + "," + r + " " + degrees + " " + ( degrees >= 180 ? "1" : "0" ) + " 1 " + ( x + ( r * Math.cos( radians ) ) ) + "," + ( y + ( r * Math.sin( radians ) ) ),
        "z"
    ];

    return draw_progress.path( pathparts );
}

function animate(x, y, r, startAngle, endAngle, progress) {
	var today = new Date();
	var m = today.getMilliseconds();
	console.log('startAngle ' + startAngle + ' - ' + m);
	console.log('endAngle ' + endAngle);
	console.log('progress ' + progress);
	var arcCircle = draqArc(x, y, r, startAngle, endAngle);
	arcCircle.attr({"stroke": "green", "stroke-width": 15});
	if (progress > 1) {
		progress--
		endAngle = endAngle - 1
		setTimeout(animate(x, y, r, startAngle, endAngle, progress), 1000);
	};
}

function draqArc(centerX, centerY, radius, startAngle, endAngle) {
  var startX = centerX+radius*Math.cos(startAngle*Math.PI/180); 
  var startY = centerY+radius*Math.sin(startAngle*Math.PI/180);
  var endX = centerX+radius*Math.cos(endAngle*Math.PI/180); 
  var endY = centerY+radius*Math.sin(endAngle*Math.PI/180);
  return arc(startX, startY, endX-startX, endY-startY, radius, radius, 0);
  
};

function arc(startX, startY, endX, endY, radius1, radius2, angle) {
  var arcSVG = [radius1, radius2, angle, 0, 1, endX, endY].join(' ');
  return draw_progress.path('M'+startX+' '+startY + " a " + arcSVG);
};

//Helper method to take x,y and r and return a path instruction string. x and y are center and r is the radius
function getCircletoPath(x , y, r)  {  
	return "M"+ x + "," + (y - r) + "A" + r + "," + r + ",0,1,1," + (x - 0.1) + "," + (y - r) +" z"; 
}