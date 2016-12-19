// ECS 163 Final Project
// Zachary Chapman
// Evan Frenkel

// imports
import java.util.*;

// variables
ArrayList<Widget> allWidgets;
ArrayList<Car> allCars;
ArrayList<String> axisAttrs;
Car minCar, maxCar;
Widget nullWidget;
Widget overWidget;
int selectX, selectY;
int frames;

// global setup
void setup() {
  frameRate(30);
  size(1000, 700);
  frames = 0;
  smooth();
  colorMode(HSB, 360, 100, 100, 100);
  selectX = 0;
  selectY = 0;
  nullWidget = new Widget(0,0,0,0);
  overWidget = nullWidget;
  allWidgets = new ArrayList<Widget>();
  allCars = new ArrayList<Car>();
  // axis attributes
  axisAttrs = new ArrayList<String>();
  axisAttrs.add("MPG");
  axisAttrs.add("Cylinders");
  axisAttrs.add("Displacement");
  axisAttrs.add("Horsepower");
  axisAttrs.add("Weight");
  axisAttrs.add("Acceleration");
  axisAttrs.add("Year");
  axisAttrs.add("Origin");
  // load data
  loadCars();
  Collections.sort(allCars, new Comparator<Car>() {
    public int compare(Car left, Car right) {
      return int(1000 * (right.mpg - left.mpg));
    }
  });
  // CarInfo
  CarInfo ci = new CarInfo(585, 480, 300, 200);
  // CarList
  CarList cl = new CarList(630, 70, 300, 399);
  cl.carinfo = ci;
  // HeatMap
  HeatMap hm = new HeatMap(84,70,496,496);
  hm.xAttr = "Acceleration";
  hm.yAttr = "Year";
  hm.carlist = cl;
  hm.setup();
  // X dropdown
  Dropdown ddx = new Dropdown(375,640,150,30);
  ddx.label = "X: ";
  ddx.selection = "Acceleration";
  ddx.menu = axisAttrs;
  ddx.axis = 'x';
  ddx.heatmap = hm;
  // Y dropdown
  Dropdown ddy = new Dropdown(140, 640, 150, 30);
  ddy.label = "Y: ";
  ddy.selection = "Year";
  ddy.menu = axisAttrs;
  ddy.axis = 'y';
  ddy.heatmap = hm;
  // add in order of most visible first
  add(ddx);
  add(ddy);
  add(ci);
  add(cl);
  add(hm);
}

// draw loop
void draw() {
  if (!mousePressed) {
    selectX = mouseX;
    selectY = mouseY;
  }
  if (frames <= 0) {
    background(0,0,100);
    textSize(26);
    fill(0);
    textAlign(CENTER, TOP);
    text("MPG", 350, 30);
    overWidget = getMouseOver();
    for (int i = allWidgets.size() - 1; i >= 0; i--) {
      allWidgets.get(i).draw();
    }
  }
  else {
    overWidget = nullWidget;
    for (int i = allWidgets.size() - 1; i >= 0; i--) {
      allWidgets.get(i).animate();
    }
    frames--;
  }
}
// mouse clicked
void mouseClicked() {
  if (frames <= 0) {
    overWidget.mouseClicked();
  }
}
// mouse dragged
void mouseDragged() {
  if (frames <= 0) {
    overWidget.mouseDragged();
  }
}
// mouse wheel
void mouseWheel(MouseEvent e) {
  if (frames <= 0) {
    overWidget.mouseWheel(e.getCount());
  }
}

// parent widget
class Widget {
  int x, y, w, h;
  
  Widget(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  boolean mouseOver() {
    return mouseIn(x, y, w, h);
  }
  
  void draw() {
  }
  void animate() {
  }
  void mouseClicked() {
  }
  void mouseDragged() {
  }
  void mouseWheel(float count) {
  }
}

// Dropdown selection widget
class Dropdown extends Widget {
  String label;
  String selection;
  ArrayList<String> menu;
  boolean selecting;
  int baseH, baseY, pad;
  HeatMap heatmap;
  char axis;
  
  Dropdown(int x, int y, int w, int h) {
    super(x, y, w, h);
    baseH = h;
    baseY = y;
    pad = 6;
  }
  
  int menuHeight() {
    return menu.size() * baseH;
  }
  
  void draw() {
    textSize(baseH - 2 * pad);
    textAlign(LEFT, TOP);
    if (selecting) {
      int currY = y;
      noStroke();
      fill(0,0,100,90);
      rect(x, y, w, h);
      for (String item: menu) {
        if (mouseIn(x, currY, w, baseH)) {
          fill(0,0,80,90);
          rect(x, currY, w, baseH);
        }
        fill(0,0,0);
        text(item, x + pad, currY + pad / 2);
        currY += baseH;
      }
      stroke(0,0,0);
      fill(0,0,0,0);
      rect(x, y, w, menuHeight());
    }
    stroke(0,0,0);
    fill(0,0,100);
    rect(x, baseY, w, baseH);
    fill(0,0,0);
    text(selection, x + pad, baseY + pad / 2);
    text(label, x - textWidth(label) - pad, baseY + pad/2);
    fill(0,0,100);
    triangle(x + w - 16 - pad, baseY + pad, x + w - pad, baseY + pad, x + w - 8 - pad, baseY + baseH - pad);
  }
  
  // mouse clicked
  void mouseClicked() {
    if (selecting) {
      int index = (mouseY - y) / baseH;
      if (index < menu.size()) {
        selection = menu.get(index);
        heatmap.setAttr(axis, selection);
      }
      y += menuHeight();
      h -= menuHeight();
      selecting = false;
    }
    else {
      y -= menuHeight();
      h += menuHeight();
      selecting = true;
    }
  }
}

//// Heat Map widget
class HeatMap extends Widget {
  String xAttr, yAttr;
  float minX, minY, maxX, maxY;
  ArrayList<ArrayList<ArrayList<Car>>> data;
  int divs;
  int startX, stopX, startY, stopY;
  int startIndX, stopIndX, startIndY, stopIndY;
  boolean activeSelect;
  CarList carlist;
  int pad;
  
  // constructor
  HeatMap(int x, int y, int w, int h) {
    super(x, y, w, h);
    divs = 16;
    pad = 3;
    data = new ArrayList<ArrayList<ArrayList<Car>>>();
    for (int i = 0; i < divs; i++) {
      ArrayList<ArrayList<Car>> al = new ArrayList<ArrayList<Car>>();
      for (int j = 0; j < divs; j++) {
        al.add(new ArrayList<Car>());
      }
      data.add(al);
    }
    divs = 8;
    resetSelection();
  }
  
  // reset selection area
  void resetSelection() {
    startX = x; startY = y;
    stopX = w; stopY = h;
    startIndX = 0; startIndY = 0;
    stopIndX = divs - 1; stopIndY = divs - 1;
    activeSelect = false;
    if (carlist != null) {
      carlist.highlighted = null;
    }
  }
  
  // setup heatmap's display area
  void setup() {
    for (int i = 0; i < divs; i++) {
      for (int j = 0; j < divs; j++) {
        getData(i, j).clear();
      }
    }
    minX = minCar.get(xAttr);
    minY = minCar.get(yAttr);
    maxX = maxCar.get(xAttr);
    maxY = maxCar.get(yAttr);
    int i, j;
    boolean filter = !(xAttr.equals("Horsepower") || yAttr.equals("Horsepower"));
    for (Car car: allCars) {
      if (filter || car.hasHorsepower) {
        i = (int) map(car.get(xAttr), minX, maxX, 0, divs);
        j = (int) map(car.get(yAttr), minY, maxY, 0, divs);
        addData(i, j, car);
      }
    }
  }
  
  // set attr for x or y
  void setAttr(char name, String value) {
    if (name == 'x') {
      xAttr = value;
    }
    else if (name == 'y') {
      yAttr = value;
    }
    setup();
  }
  
  // set data at indexes
  void addData(int i, int j, Car d) {
    i = max(i, 0);
    j = max(j, 0);
    i = min(i, divs - 1);
    j = min(j, divs - 1);
    getData(i, j).add(d);
  }
  
  // get data at indexes
  ArrayList<Car> getData(int i, int j) {
    return data.get(i).get(j);
  }
  
  // average mpg at heatmap point
  float avgMpg(int i, int j) {
    float total = 0;
    int number = 0;
    for (Car car: getData(i, j)) {
      total += car.mpg;
      number++;
    }
    return total / number;
  }
  
  // animate HeatMap
  void animate() {
    resetSelection();
    int divW = w / divs;
    int divH = h / divs;
    noStroke();
    for (int i = 0; i < divs; i++) {
      for (int j = 0; j < divs; j++) {
        if (getData(i, j).size() == 0) {
          fill(0,0,95,20);
        } else {
          int av = mpgHue(avgMpg(i,j));
          int sel = 85;
          fill(av, sel, 100, 20);
        }
        rect(x + i * divW, y + (divs - j - 1) * divH, divW, divH);
      }
    }
    fill(0,0);
    stroke(0,0,70);
    rect(x, y, w, h);
  }
  
  // draw HeatMap
  void draw() {
    if (!activeSelect) {
      if (this == overWidget && mouseOver()) {
        this.mouseMoved();
      } else {
        resetSelection();
      }
    }
    int divW = w / divs;
    int divH = h / divs;
    noStroke();
    for (int i = 0; i < divs; i++) {
      for (int j = 0; j < divs; j++) {
        if (getData(i, j).size() == 0) {
          fill(0,0,95);
        } else {
          int av = mpgHue(avgMpg(i,j));
          int sel = 85;
          if (this == overWidget && !mousePressed && mouseIn(startX, startY, stopX, stopY)
              && from(i, startIndX, stopIndX) && from(j, startIndY, stopIndY)) {
            sel = 75;
          }
          fill(av, sel, 100);
        }
        rect(x + i * divW, y + (divs - j - 1) * divH, divW, divH);
      }
    }
    stroke(0);
    fill(0);
    textSize(20);
    textAlign(LEFT, TOP);
    text(roundStr(minX), x, y + h + pad);
    textAlign(CENTER, TOP);
    text(roundStr((minX + maxX)/2), x + w/2, y + h + pad);
    text(xAttr, x + w/2, y + h + 30);
    textAlign(RIGHT, TOP);
    text(roundStr(maxX), x + w, y + h + pad);
    text(roundStr(maxY), x - pad, y);
    textAlign(RIGHT, CENTER);
    text(roundStr((minY + maxY)/2), x - pad, y + h/2);
    textAlign(CENTER, BOTTOM);
    pushMatrix();
    translate(x - textWidth(((Integer) roundStr((minY + maxY)/2)).toString()) - 6, y + h/2);
    rotate(radians(-90));
    text(yAttr, 0, 0);
    popMatrix();
    textAlign(RIGHT, BOTTOM);
    text(roundStr(minY), x - pad, y + h);
    fill(0,0);
    stroke(0,0,70);
    rect(x, y, w, h);
    if (activeSelect || startIndX == stopIndX) {
      stroke(0);
      rect(startX, startY, stopX, stopY);
    }
  }
  
  // mouse clicked on HeatMap
  void mouseClicked() {
    if (!activeSelect && mouseIn(startX, startY, stopX, stopY)) {
      activeSelect = true;
    }
    else {
      resetSelection();
    }
  }
  
  // mouse dragged on HeatMap
  void mouseDragged() {
    activeSelect = true;
    mouseMoved();
  }
  // mouse moved on HeatMap
  void mouseMoved() {
    int mX = min(max(x, mouseX), x + w - 1);
    int mY = min(max(y, mouseY), y + h - 1);
    if (selectX < mX) {
      startX = selectX;
      stopX = mX;
    } else {
      startX = mX;
      stopX = selectX;
    }
    if (selectY < mY) {
      startY = selectY;
      stopY = mY;
    } else {
      startY = mY;
      stopY = selectY;
    }
    startIndX = int((startX - x) / (w / divs));
    startIndY = int((y - startY) / (h / divs)) + divs - 1;
    stopIndX = int((stopX - x) / (w / divs));
    stopIndY = int((y - stopY) / (h / divs)) + divs - 1;
    startX = int((startX - x) / (w / divs)) * w / divs + x;
    startY = int((startY - y) / (h / divs)) * h / divs + y;
    stopX = int((stopX - x) / (w / divs) + 1) * w / divs + x - startX;
    stopY = int((stopY - y) / (h / divs) + 1) * h / divs + y - startY;
    carlist.highlighted = new ArrayList<Car>();
    for (int i = 0; i < divs; i++) {
      for (int j = 0; j < divs; j++) {
        if (from(i, startIndX, stopIndX) && from(j, startIndY, stopIndY)) {
          carlist.highlighted.addAll(getData(i, j));
        }
      }
    }
  }
  
  // mouse wheel HeatMap
  void mouseWheel(float count) {
    int c = (int) count;
    if (c > 0 && divs > 4) {
      frames = 15;
      divs /= 2;
      c--;
    }
    else if (c < 0 && divs < 16) {
      frames = 15;
      divs *= 2;
      c++;
    }
    setup();
  }
}

int mpgHue(float value) {
  return (int) map(value, minCar.mpg, maxCar.mpg, 0, 120);
}

int roundStr(float value) {
  return (int) (value + .5);
}

//// list of all cars
class CarList extends Widget {
  ArrayList<Car> highlighted;
  CarInfo carinfo;
  boolean zoomed;
  int scrollPos, scrollMax;
  
  CarList(int x, int y, int w, int h) {
    super(x, y, w, h);
    highlighted = null;
    zoomed = false;
    scrollPos = 0;
    scrollMax = 379;
  }
  
  // draw CarList
  void draw() {
    stroke(0,0,70);
    fill(0,0,100);
    rect(x, y, w, h);
    int currY = y + 1;
    int total = 0;
    if (zoomed) {
      int currH = 20;
      int currPos = scrollPos;
      int i = 0;
      for (Car car: allCars) {
        int sat = 90;
        noStroke();
        textAlign(LEFT, TOP);
        textSize(16);
        if (highlighted == null || highlighted.contains(car)) {
          if (total >= scrollPos && i < 20) {
            if (mouseY >= currY && mouseY < currY + currH && this == overWidget) {
              carinfo.car = car;
              fill(0);
              rect(x - 3, currY, 3, currH);
              rect(x + w, currY, 3, currH);
            }
            else if (carinfo.car == car && this != overWidget) {
              fill(0);
              rect(x - 3, currY, 3, currH);
              rect(x + w, currY, 3, currH);
            }
            fill(mpgHue(car.mpg), sat, 100);
            rect(x + 1, currY, w - 1, currH);
            fill(0);
            text(car.name, x + 5, currY - 2);
            currY += currH;
            i++;
          }
          total++;
        }
      }
      scrollMax = max(total - 20, 0);
      scrollPos = min(scrollPos, scrollMax);
    }
    else {
      for (Car car: allCars) {
        int sat = 15;
        if (highlighted == null || highlighted.contains(car)) {
          sat = 90;
          total++;
        }
        if (mouseY == currY && this == overWidget) {
          carinfo.car = car;
          stroke(0);
          line(x - 3, currY, x, currY);
          line(x + w, currY, x + w + 3, currY);
        }
        else if (carinfo.car == car && this != overWidget) {
          stroke(0);
          line(x - 3, currY, x, currY);
          line(x + w, currY, x + w + 3, currY);
        }
        stroke(mpgHue(car.mpg), sat, 100);
        line(x + 1, currY, x + w - 1, currY);
        currY++;
      }
    }
    textAlign(RIGHT, BOTTOM);
    fill(0);
    textSize(20);
    text(total, x + w * 3/10, y);
    text("Cars Selected", x + w * 4/5 - 10, y);
  }
  
  // mouse clicked on CarList
  void mouseClicked() {
    zoomed = !zoomed;
    scrollPos = max(0, min(mouseY - y - 11, scrollMax));
    if (zoomed) {
      h += 2;
    }
    else {
      h -= 2;
    }
  }
  
  // mouse wheel on CarList
  void mouseWheel(float count) {
    scrollPos += count;
    scrollPos = max(0, min(scrollPos, scrollMax));
  }
}

class CarInfo extends Widget {
  Car car;
  int currX, currY;
  
  CarInfo(int x, int y, int w, int h) {
    super(x, y, w, h);
    car = null;
  }
  
  // draw CarInfo
  void draw() {
    currY = y + 5;
    //stroke(0,0,70);
    //fill(0,0,100);
    //rect(x, y, w, h);
    textSize(16);
    textAlign(RIGHT, TOP);
    currX = x + (int) textWidth("Displacement: ");
    fill(0);
    write("Name:");
    write("MPG:");
    write("Cylinders:");
    write("Displacement:");
    write("Horsepower:");
    write("Weight:");
    write("Acceleration:");
    write("Year:");
    write("Origin:");
    if (car != null) {
      currX += 10;
      currY = y + 5;
      textAlign(LEFT, TOP);
      write(car.name);
      write("" + car.mpg);
      write("" + car.cylinders);
      write("" + car.displacement);
      write("" + car.horsepower);
      write("" + car.weight);
      write("" + car.acceleration);
      write("" + car.modelYear);
      write("" + car.origin);
    }
  }
  
  // write text
  void write(String t) {
    text(t, currX, currY);
    currY += 20;
  }
}

// test if first number is between or equal to the other two
boolean from(int v, int a, int b) {
  if (a > b) {
    return v >= b && v <= a;
  } else {
    return v >= a && v <= b;
  }
}

// add a widget to the display
void add(Widget widget) {
  allWidgets.add(widget);
}

// get the widget that the mouse is over
Widget getMouseOver() {
  for (Widget widget: allWidgets) {
    if (widget.mouseOver()) {
      return widget;
    }
  }
  return nullWidget;
}

// true if mouse in rectangle
boolean mouseIn(int x, int y, int w, int h) {
  return selectX >= x && selectX <= x + w && selectY >= y && selectY <= y + h;
}

// load car data
void loadCars() {
  String[] rows = loadStrings("auto-mpg.data");
  for (String row: rows) {
    String[] cols = row.split("\t");
    Car car = new Car();
    car.mpg = Float.valueOf(cols[0]);
    car.cylinders = Integer.valueOf(cols[1]);
    car.displacement = Float.valueOf(cols[2]);
    if (cols[3].equals("?")) {
      car.hasHorsepower = false;
    } else {
      car.horsepower = Float.valueOf(cols[3]);
      car.hasHorsepower = true;
    }
    car.weight = Float.valueOf(cols[4]);
    car.acceleration = Float.valueOf(cols[5]);
    car.modelYear = Integer.valueOf(cols[6]);
    car.origin = Integer.valueOf(cols[7]);
    car.name = cols[8].substring(1, cols[8].length()-1);
    allCars.add(car);
  }
  minCar = allCars.get(0).clone();
  minCar.name = "minCar";
  maxCar = allCars.get(0).clone();
  maxCar.name = "maxCar";
  for (Car car: allCars) {
    // mpg
    minCar.mpg = min(minCar.mpg, car.mpg);
    maxCar.mpg = max(maxCar.mpg, car.mpg);
    // displacement
    minCar.displacement = min(minCar.displacement, car.displacement);
    maxCar.displacement = max(maxCar.displacement, car.displacement);
    // horsepower
    if (car.hasHorsepower) {
      minCar.horsepower = min(minCar.horsepower, car.horsepower);
      maxCar.horsepower = max(maxCar.horsepower, car.horsepower);
    }
    // weight
    minCar.weight = min(minCar.weight, car.weight);
    maxCar.weight = max(maxCar.weight, car.weight);
    // acceleration
    minCar.acceleration = min(minCar.acceleration, car.acceleration);
    maxCar.acceleration = max(maxCar.acceleration, car.acceleration);
    // cylinders
    minCar.cylinders = min(minCar.cylinders, car.cylinders);
    maxCar.cylinders = max(maxCar.cylinders, car.cylinders);
    // modelYear
    minCar.modelYear = min(minCar.modelYear, car.modelYear);
    maxCar.modelYear = max(maxCar.modelYear, car.modelYear);
    // origin
    minCar.origin = min(minCar.origin, car.origin);
    maxCar.origin = max(maxCar.origin, car.origin);
  }
}

// car
class Car {
  float mpg, displacement, horsepower, weight, acceleration;
  boolean hasHorsepower;
  int cylinders, modelYear, origin;
  String name;
  
  float get(String k) {
    if (k.equals("MPG")) {
      return mpg;
    }
    else if (k.equals("Displacement")) {
      return displacement;
    }
    else if (k.equals("Horsepower")) {
      return horsepower;
    }
    else if (k.equals("Weight")) {
      return weight;
    }
    else if (k.equals("Acceleration")) {
      return acceleration;
    }
    else if (k.equals("Cylinders")) {
      return cylinders;
    }
    else if (k.equals("Year")) {
      return modelYear;
    }
    else if (k.equals("Origin")) {
      return origin;
    }
    else {
      println(k);
      throw new IllegalArgumentException();
    }
  }
  
  Car clone() {
    Car car = new Car();
    car.mpg = mpg;
    car.displacement = displacement;
    car.horsepower = horsepower;
    car.weight = weight;
    car.acceleration = acceleration;
    car.hasHorsepower = hasHorsepower;
    car.cylinders = cylinders;
    car.modelYear = modelYear;
    car.origin = origin;
    car.name = name;
    return car;
  }
}
