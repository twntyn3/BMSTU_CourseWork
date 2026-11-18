#include <GLFW/glfw3.h>

#include <algorithm>
#include <cmath>
#include <iostream>
#include <string>
#include <vector>

using namespace std;
const double EPS = 1e-9;

struct Point {
    double x;
    double y;

};

enum class InputStage {
    SubjectInput,
    ClipperInput,
    ReadyToClip
};

vector<Point> subjectPolygon;
vector<Point> clipperPolygon;
vector<Point> resultPolygon;

InputStage stage = InputStage::SubjectInput;

int windowWidth = 1000;
int windowHeight = 700;


bool clipDone = false;

double cross(const Point& a, const Point& b, const Point& c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}


//вычисл ориентированной площади

//potom otsuda idem ewe k isinside tk value ne modulu


double polygonArea2(const vector<Point>& poly) {
    double sum = 0.0;
    int n = (int)poly.size();

    for (int i = 0; i < n; i++) {
        int j = (i + 1) % n;
        sum += poly[i].x * poly[j].y - poly[j].x * poly[i].y;
    }

    return sum;
}



bool isConvex(const vector<Point>& poly) {
    int n = (int)poly.size();
    if (n < 3) {
        return false;
    }

    int sign = 0;
//выпуклость знаком поворота
    for (int i = 0; i < n; i++) {
        const Point& a = poly[i];
        const Point& b = poly[(i + 1) % n];
        const Point& c = poly[(i + 2) % n];

        double cr = cross(a, b, c);

        if (fabs(cr) < EPS) {
            continue;
        }

        if (cr > 0) {
            if (sign < 0) {
                return false;
            }
            sign = 1;
        } else {
            if (sign > 0) {
                return false;
            }
            sign = -1;
        }
    }

    return true;
}



bool isInside(const Point& p, const Point& a, const Point& b, bool clipperCCW) {
    double value = cross(a, b, p);

    if (clipperCCW) {
        return value >= -EPS;
    }
    return value <= EPS;
}



Point intersection(const Point& s, const Point& e, const Point& a, const Point& b) {
    Point se{e.x - s.x, e.y - s.y};
    Point ab{b.x - a.x, b.y - a.y};
    Point as{a.x - s.x, a.y - s.y};

    double denom = se.x * ab.y - se.y * ab.x; // P(t) = S + t(E-S)

    if (fabs(denom) < EPS) {
        return s; //zash mex ot /0
    }

    double t = (as.x * ab.y - as.y * ab.x) / denom;

    Point p;
    p.x = s.x + t * se.x;
    p.y = s.y + t * se.y;
    return p;
}


//operaciya odnogo waga otse4eniya 

vector<Point> clipByEdge(const vector<Point>& polygon, const Point& a, const Point& b, bool clipperCCW) {
    vector<Point> result;

    if (polygon.empty()) {

        return result;
    }

    Point s = polygon.back();

    for (const Point& e : polygon) {
        bool sInside = isInside(s, a, b, clipperCCW);
        bool eInside = isInside(e, a, b, clipperCCW);
//4 slu4aya
        if (sInside && eInside) {
            result.push_back(e);
        } else if (sInside && !eInside) {
            Point inter = intersection(s, e, a, b);
            result.push_back(inter);
        } else if (!sInside && eInside) {
            Point inter = intersection(s, e, a, b);
            result.push_back(inter);
            result.push_back(e);
        }

        s = e;
    }

    return result;
}



vector<Point> sutherlandHodgman(const vector<Point>& subject, const vector<Point>& clipper) {
    if (subject.size() < 3 || clipper.size() < 3) {
        return {};
    }

    vector<Point> result = subject;
    bool clipperCCW = polygonArea2(clipper) > 0.0;

    for (int i = 0; i < (int)clipper.size(); i++) {
        int j = (i + 1) % (int)clipper.size();
        result = clipByEdge(result, clipper[i], clipper[j], clipperCCW);

        if (result.empty()) {
            break;
        }
    }

    return result;
}       


Point screenToWorld(double mouseX, double mouseY) {
    Point p;
    p.x = mouseX;
    p.y = mouseY;
    return p;
}


void printHelp() {
    cout << "\nУправление:\n";
    cout << "ЛКМ        - добавить вершину текущей фигуры\n";
    cout << "Enter      - завершить ввод текущей фигуры\n";
    cout << "Backspace  - удалить последнюю точку текущей фигуры\n";
    cout << "Space      - выполнить отсечение\n";
    cout << "C          - очистить\n";
    cout << "Esc        - выход\n\n";


}


void clearAll() {
    subjectPolygon.clear();
    clipperPolygon.clear();
    resultPolygon.clear();
    stage = InputStage::SubjectInput;
    clipDone = false;
    cout << "Сцена очищена.\n";
}

// perexod rezhimov
void finishCurrentPolygon() {
    if (stage == InputStage::SubjectInput) {
        if (subjectPolygon.size() < 3) {
            return;
        }

        stage = InputStage::ClipperInput;
        cout << "Ввод отсекаемого многоугольника завершен.\n";
        return;
    }

    if (stage == InputStage::ClipperInput) {
        if (clipperPolygon.size() < 3) {
            cout << "У отсекателя должно быть минимум 3 вершины.\n";
            return;
        }

        if (!isConvex(clipperPolygon)) {
            cout << "Ошибка: отсекатель должен быть выпуклым.\n";
            return;
        }

        stage = InputStage::ReadyToClip;
        cout << "Ввод отсекателя завершен.\n";
        cout << "Нажмите пробел для выполнения отсечения.\n";
    }
}


// zakraska
void performClipping() {
    if (stage != InputStage::ReadyToClip) {
        cout << "Сначала завершите ввод обеих фигур.\n";
        return;
    }

    resultPolygon = sutherlandHodgman(subjectPolygon, clipperPolygon);
    clipDone = true;

    if (resultPolygon.empty()) {
        cout << "Результат отсечения пуст.\n";
    } else {
        cout << "Отсечение выполнено. Число вершин результата: " << resultPolygon.size() << "\n";
    }
}




void addPointToCurrentPolygon(const Point& p) {
    if (stage == InputStage::SubjectInput) {
        subjectPolygon.push_back(p);
        clipDone = false;
        resultPolygon.clear();
        return;
    }

    if (stage == InputStage::ClipperInput) {
        clipperPolygon.push_back(p);
        clipDone = false;
        resultPolygon.clear();
        return;
    }
}


//risuem kontur figurbl i ee vershinbl
void drawPolyline(const vector<Point>& poly, bool closed, float r, float g, float b) {
    if (poly.empty()) {
        return;
    }

    glColor3f(r, g, b);

    if (closed && poly.size() >= 2) {
        glBegin(GL_LINE_LOOP);
        for (const Point& p : poly) {
            glVertex2d(p.x, p.y);
        }
        glEnd();
    } else {
        glBegin(GL_LINE_STRIP);
        for (const Point& p : poly) {
            glVertex2d(p.x, p.y);
        }
        glEnd();
    }

    glPointSize(6.0f);
    glBegin(GL_POINTS);
    for (const Point& p : poly) {
        glVertex2d(p.x, p.y);
    }
    glEnd();
}

//zakrash polyprozra4niy mnogougol'nik
void drawFilledPolygon(const vector<Point>& poly, float r, float g, float b, float alpha) {
    if (poly.size() < 3) {
        return;
    }

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glColor4f(r, g, b, alpha);
    glBegin(GL_POLYGON);
    for (const Point& p : poly) {
        glVertex2d(p.x, p.y);
    }
    glEnd();

    glDisable(GL_BLEND);
}


void drawScene() {
    glClear(GL_COLOR_BUFFER_BIT);

    if (clipDone && resultPolygon.size() >= 3) {
        drawFilledPolygon(resultPolygon, 1.0f, 0.0f, 0.0f, 0.28f);
    }

    if (!subjectPolygon.empty()) {
        bool closed = (stage != InputStage::SubjectInput);
        drawPolyline(subjectPolygon, closed, 0.1f, 0.4f, 1.0f);
    }

    if (!clipperPolygon.empty()) {
        bool closed = (stage == InputStage::ReadyToClip);
        drawPolyline(clipperPolygon, closed, 0.1f, 0.8f, 0.2f);
    }

    if (clipDone && !resultPolygon.empty()) {
        drawPolyline(resultPolygon, true, 1.0f, 0.0f, 0.0f);
    }
}

void framebufferSizeCallback(GLFWwindow* window, int width, int height) {
    windowWidth = width;
    windowHeight = height;

    glViewport(0, 0, width, height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0, (double)width, (double)height, 0.0, -1.0, 1.0);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}




void mouseButtonCallback(GLFWwindow* window, int button, int action, int mods) {
    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        double mouseX = 0.0;
        double mouseY = 0.0;
        glfwGetCursorPos(window, &mouseX, &mouseY);

        Point p = screenToWorld(mouseX, mouseY);
        addPointToCurrentPolygon(p);

        cout << "Добавлена точка: (" << p.x << ", " << p.y << ")\n";
    }
}



void keyCallback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    if (action != GLFW_PRESS) {
        return;
    }

    if (key == GLFW_KEY_ESCAPE) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
        return;
    }

    if (key == GLFW_KEY_C) {
        clearAll();
        return;
    }

    if (key == GLFW_KEY_ENTER) {
        finishCurrentPolygon();
        return;
    }

    if (key == GLFW_KEY_SPACE) {
        performClipping();
        return;
    }

}


int main() {
    if (!glfwInit()) {
        cerr << "Ошибка: не удалось инициализировать GLFW.\n";
        return 1;
    }

    GLFWwindow* window = glfwCreateWindow(windowWidth, windowHeight, "Sutherland-Hodgman Clipping", nullptr, nullptr);
    if (!window) {
        cerr << "Ошибка: не удалось создать окно.\n";
        glfwTerminate();
        return 1;
    }

    glfwMakeContextCurrent(window);

    glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    glfwSetMouseButtonCallback(window, mouseButtonCallback);
    glfwSetKeyCallback(window, keyCallback);

    framebufferSizeCallback(window, windowWidth, windowHeight);

    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);

    printHelp();


    while (!glfwWindowShouldClose(window)) {
        glLoadIdentity();
        drawScene();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}