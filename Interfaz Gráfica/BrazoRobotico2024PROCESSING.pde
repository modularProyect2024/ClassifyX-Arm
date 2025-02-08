import processing.serial.*;
import controlP5.*;
import java.util.ArrayList;
import g4p_controls.*;
PImage P;
PImage P2;
float scaleFactor;


boolean isFullscreen = false; // Variable de estado para almacenar si la aplicación está en modo de pantalla completa
boolean fullscreen = false;

GButton minimizeButton, fullscreenButton, closeButton;

String fabriMessage = "Asesor: Dr. José de Jesús Hernández Barragán";
ArrayList<Message> messages = new ArrayList<>();
int fadeOutDuration = 3000; // Duración de desvanecimiento en milisegundos

Serial myPort;
ControlP5 cp5;
String[] portList;
ArrayList<ArrayList<Integer>> movimientosGuardados;
boolean reproduciendo = false;
int velocidadReproduccion = 500; // Velocidad inicial de reproducción en milisegundos
int movimientoActual = 0;


class Message {
  String text;
  int timestamp;

  Message(String text) {
    this.text = text;
    this.timestamp = millis();
  }

  void display(float x, float y) {
    int alpha = 255;
    int elapsedTime = millis() - timestamp;
    if (elapsedTime < fadeOutDuration) {
      alpha = (int) map(elapsedTime, 0, fadeOutDuration, 255, 0);
    }
    fill(0, alpha);
    textAlign(CENTER);
    text(text, x, y);
  }

  boolean isExpired() {
    return millis() - timestamp > fadeOutDuration;
  }
}

void setup() {
  
  size(displayWidth, displayHeight);  // Habilitar el modo de pantalla completa
  scaleFactor = min(width, height) / 1000.0; // Establece el factor de escala basado en las dimensiones de la pantalla

  P = loadImage("logoOficial.png");
  

  surface.setResizable(true); // Permitir redimensionar la ventana
  
  fullScreen(); // Establece el modo pantalla completa
  cp5 = new ControlP5(this);

  // Obtener lista de puertos disponibles
  portList = Serial.list();

  if (portList.length > 0) {
      // Si hay puertos disponibles, configurar el menú desplegable para seleccionar el puerto COM
      cp5.addDropdownList("portDropdown")
         .setPosition((int)(width * 0.03), (int)(height * 0.02))
         .setSize((int)(width * 0.11), (int)(height * 0.1))
         .setBarHeight((int)(height * 0.02))
         .setItemHeight((int)(height * 0.02))
         .setCaptionLabel("SELECCIONA EL PUERTO")
         .setItems(portList);
          // Configurar el puerto serial
         myPort = new Serial(this, Serial.list()[0], 9600);
    } else {
      println("No serial ports available.");
    }
  actualizarPuertos();


      
  // Calcular la altura total ocupada por las barras deslizadoras y espacios entre ellas
  int totalSliderHeight = (int)(6 * height * 0.04); // 6 barras deslizadoras, cada una con 10% de la altura de la pantalla
  int totalSpacing = (int)(5 * height * 0.05); // Espacio entre cada barra deslizadora, 5 en total
  
  // Calcular la posición Y de inicio para centrar las barras deslizadoras verticalmente
  int startY = (height - totalSliderHeight - totalSpacing) / 2;
    
  // Configurar barras deslizadoras para controlar los servomotores
  int sliderWidth = (int)(width * 0.35); // Ancho de la barra deslizadora
  int sliderX = (width - sliderWidth + 350) / 2; // Calcular la posición X para centrar la barra deslizadora
  for (int i = 0; i < 6; i++) {
    Slider slider = cp5.addSlider("servo_" + (i + 1))
      .setPosition(sliderX, startY + i * ((int)(height * 0.1) + (int)(height * 0.01)))
      .setSize(sliderWidth, (int)(height * 0.05))
      .setCaptionLabel("Servo " + (i + 1))
      .setFont(createFont("Tahoma", 20)); // Establecer la fuente Tahoma con tamaño 15
    
    if (i == 0) {
      slider.setRange(0, 90)
            .setValue(90);
    } else {
      slider.setRange(0, 180)
            .setValue(90);
    }
    // Agregar texto personalizado en la posición deseada
    
    slider.onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        int servoIndex = Integer.parseInt(event.getController().getName().split("_")[1]);
        int servoValue = (int) event.getController().getValue();
        if (!reproduciendo) {
          myPort.write(servoIndex + " " + servoValue + "\n");
        }
      }
    });
  }



    
  // Configurar botón para cerrar
  cp5.addButton("cerrar")
     .setPosition((int)(width * 0.945), (int)(height * 0.01))
     .setSize((int)(width * 0.05), (int)(height * 0.05))
     .setCaptionLabel("SALIR")
     .setFont(createFont("Tahoma", 15)); // Establecer la fuente Tahoma con tamaño 15
  
  // Inicializar lista de listas para guardar movimientos
  movimientosGuardados = new ArrayList<ArrayList<Integer>>();
  
  // Configurar botón para guardar movimientos
  cp5.addButton("guardarMovimientos")
     .setPosition((int)(width * 0.03), (int)(height * 0.3))
     .setSize((int)(width * 0.18), (int)(height * 0.10))
     .setCaptionLabel("Guardar Posiciones")
     .setFont(createFont("Tahoma", 25)); // Establecer la fuente Tahoma con tamaño 15
  
  // Configurar botón para reproducir movimientos
  cp5.addButton("reproducirMovimientos")
     .setPosition((int)(width * 0.03), (int)(height * 0.45))
     .setSize((int)(width * 0.18), (int)(height * 0.10))
     .setCaptionLabel("Reproducir Movimientos")
     .setFont(createFont("Tahoma", 25)); // Establecer la fuente Tahoma con tamaño 15
  
  // Configurar botón para detener movimiento
  cp5.addButton("detenerMovimiento")
     .setPosition((int)(width * 0.03), (int)(height * 0.6))
     .setSize((int)(width * 0.18), (int)(height * 0.10))
     .setCaptionLabel("Detener Movimiento")
     .setFont(createFont("Tahoma", 25)); // Establecer la fuente Tahoma con tamaño 15
  
  // Configurar control deslizante para regular la velocidad de reproducción
  cp5.addSlider("velocidadReproduccion")
     .setPosition((int)(width * 0.03), (int)(height * 0.75))
     .setSize((int)(width * 0.18), (int)(height * 0.05))
     .setRange(200, 2000)
     .setValue(velocidadReproduccion)
     .setCaptionLabel("")
     .setFont(createFont("Tahoma", 25)); // Establecer la fuente Tahoma con tamaño 15
  actualizarVelocidadReproduccion();
  // Configurar botón para exportar posiciones guardadas
  cp5.addButton("exportarPosiciones")
     .setPosition((int)(width * 0.8), (int)(height * 0.3))
     .setSize((int)(width * 0.18), (int)(height * 0.10))
     .setCaptionLabel("Exportar Posiciones")
     .setFont(createFont("Tahoma", 25)); // Establecer la fuente Tahoma con tamaño 15

    
  // Botón para importar posiciones guardadas
  cp5.addButton("importarPosiciones")
     .setPosition((int)(width * 0.8), (int)(height * 0.45))
     .setSize((int)(width * 0.18), (int)(height * 0.10))
     .setCaptionLabel("Importar Posiciones")
     .setFont(createFont("Tahoma", 25)); // Establecer un tamaño de fuente más grande, por ejemplo, 20


// Botón para restablecer posiciones guardadas
  cp5.addButton("resetearPosiciones")
     .setPosition((int)(width * 0.8), (int)(height * 0.6))
     .setSize((int)(width * 0.18), (int)(height * 0.10))
     .setLabel("Resetear Posiciones")
     .getCaptionLabel()
     .setFont(createFont("Tahoma", 25)); // Cambiar el tamaño de la fuente a 15
     
  // Cambiar el color de los botones, añadir contorno y sombra
  for (ControllerInterface<?> controller : cp5.getAll()) {
    if (controller instanceof Button) {
      ((Button) controller).setColorBackground(color(0)); // Relleno negro
    ((Button) controller).setColorForeground(color(255, 0, 0)); // Contorno rojo claro
    ((Button) controller).setColorActive(color(255, 0, 0)); // Color activo rojo claro
    ((Button) controller).setColorLabel(color(255)); // Letras blancas
    ((Button) controller).setColorValueLabel(color(100)); // Sombra de letras gris claro
    }
  }

  // Cambiar el color de las barras deslizadoras y añadir contorno
  for (ControllerInterface<?> controller : cp5.getAll()) {
    if (controller instanceof Slider) {
      ((Slider) controller).setColorForeground(color(0)); // Cambiar a azul
      ((Slider) controller).setColorActive(color(100, 0, 20)); // Cambiar color cuando está activo a rojo
      ((Slider) controller).setColorBackground(color(255)); // Cambiar color de relleno a negro
      ((Slider) controller).setColorValueLabel(color(255)); // Cambiar color de sombra de letras a gris

    }
  }
  
  
 P2 = loadImage("Brazo Robótico para aplicación.png");


}

void actualizarVelocidadReproduccion() {
  cp5.remove("velocidadReproduccion"); // Eliminar la barra deslizante existente
  
  cp5.addSlider("velocidadReproduccion")
     .setPosition((int)(width * 0.03), (int)(height * 0.75))
     .setSize((int)(width * 0.18), (int)(height * 0.05))
     .setRange(200, 2000)
     .setValue(1000) // Establecer el valor inicial en 1000
     .setCaptionLabel("") // Quitar la etiqueta predeterminada
     .setLabelVisible(true) // Mostrar la etiqueta del control deslizante
     .setLabel("") // Establecer el texto de la etiqueta como "velocidad"
     .setFont(createFont("Tahoma", 25)); // Establecer la fuente Tahoma con tamaño 25
}
void draw() {
  
  background(255);
  image(P2, 0, 0, width, height); // La imagen ocupará toda la pantalla   


    
  // Escala el tamaño de las letras y números
  textSize(25 * scaleFactor); // Tamaño de la letra ajustado por el factor de escala
  textAlign(CENTER, CENTER);
 
  
  String[] currentPortList = Serial.list();
  if (!sonIguales(portList, currentPortList)) {
    portList = currentPortList;
    actualizarPuertos();
  }
  
  // Dibujar "Fabri Creator" en la parte inferior
  fill(0);
  textAlign(CENTER);
  text(fabriMessage, width / 2+400, height - 50);
  
  for (int i = messages.size()-1; i >= 0; i--) {
    Message message = messages.get(i);
    float x = width / 2;
    float y = height / 2 + (messages.size() - i - 1) * 20; // Espacio vertical entre mensajes
    
    message.display(x, y);
    
    if (message.isExpired()) {
      messages.remove(i);
    }
  }

 
}







void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom("portDropdown")) {
    int selection = int(theEvent.getValue());
    String selectedPort = portList[selection];
    println("Selected port: " + selectedPort);
    myPort = new Serial(this, selectedPort, 9600);
  } else if (theEvent.isFrom("detenerMovimiento")) {
    detenerMovimiento();
  }

}


void guardarMovimientos() {
  ArrayList<Integer> movimientos = new ArrayList<Integer>();
  for (int i = 0; i < 6; i++) {
    int barValue = (int) cp5.getController("servo_" + (i + 1)).getValue();
    movimientos.add(barValue);
  }
  movimientosGuardados.add(new ArrayList<Integer>(movimientos));
  println("Movimiento guardado: " + movimientos);
  fabriMessage = "P  O  S  I  C  I  Ó  N    G  U  A  R  D  A  D  A  :   " + movimientos;
  
}

void reproducirMovimientos() {
  if (!reproduciendo && !movimientosGuardados.isEmpty()) {
    reproduciendo = true;
    println("Reproduciendo movimientos!.");
    fabriMessage =("¡  R  E  P  R  O  D  U  C  I  E  N  D  O    M  O  V  I  M  I  E  N  T  O  S  !");
    Thread thread = new Thread(new Runnable() {
      public void run() {
        while (reproduciendo) {
          int numMovimientos = movimientosGuardados.size();
          int movimientoSiguiente = (movimientoActual + 1) % numMovimientos;
          ArrayList<Integer> movimientosActuales = movimientosGuardados.get(movimientoActual);
          ArrayList<Integer> movimientosSiguientes = movimientosGuardados.get(movimientoSiguiente);
          ArrayList<Integer> currentValues = new ArrayList<Integer>();
          for (int i = 0; i < movimientosActuales.size(); i++) {
            currentValues.add((int) cp5.getController("servo_" + (i + 1)).getValue());
          }
          int steps = 50; // Número de pasos para la transición
          for (int step = 0; step <= steps; step++) {
            for (int i = 0; i < movimientosActuales.size(); i++) {
              int servoValueActual = movimientosActuales.get(i);
              int servoValueSiguiente = movimientosSiguientes.get(i);
              int currentValue = currentValues.get(i);
              int newValue = currentValue + (servoValueSiguiente - currentValue) * step / steps;
              cp5.getController("servo_" + (i + 1)).setValue(newValue);
              myPort.write((i + 1) + " " + newValue + "\n");
            }
            delay(velocidadReproduccion / steps);
          }
          movimientoActual = movimientoSiguiente;
        }
      }
    });
    thread.start();
  }
}

void detenerMovimiento() {
  // Detener cualquier movimiento adicional
  for (int i = 0; i < 6; i++) {
    int currentValue = (int) cp5.getController("servo_" + (i + 1)).getValue();
    cp5.getController("servo_" + (i + 1)).setValue(currentValue); // Detener el movimiento estableciendo el valor actual
    myPort.write((i + 1) + " " + currentValue + "\n");
  }
  reproduciendo = false; // Detener el bucle de reproducción
  println("Movimientos detenidos.");
  fabriMessage =("M  O  V  I  M  I  E  N  T  O  S    D  E  T  E  N  I  D  O  S");
}


void exportarPosiciones() {
  selectOutput("Seleccionar archivo para exportar", "guardarArchivo");
}

void guardarArchivo(File archivo) {
  if (archivo != null) {
    String[] lines = new String[movimientosGuardados.size()];
    for (int i = 0; i < movimientosGuardados.size(); i++) {
      ArrayList<Integer> movimientos = movimientosGuardados.get(i);
      StringBuilder line = new StringBuilder();
      for (Integer movimiento : movimientos) {
        line.append(movimiento).append(" ");
      }
      lines[i] = line.toString().trim();
    }
    saveStrings(archivo.getAbsolutePath(), lines);
    println("Posiciones guardadas exportadas exitosamente.");
    fabriMessage =("P  O  S  I  C  I  O  N  E  S    E  X  P  O  R  T  A  D  A  S    E  X  I  T  O  S  A  M  E  N  T  E");
    
  } else {
    println("No se seleccionó ningún archivo para exportar.");
    fabriMessage =("N  O    S  E    S  E  L  E  C  C  I  O  N  Ó    A  R  C  H  I  V  O");
  }
}

void importarPosiciones() {
  selectInput("Seleccionar archivo para importar", "cargarArchivo");
}

void cargarArchivo(File archivo) {
  if (archivo != null) {
    String[] lines = loadStrings(archivo.getAbsolutePath());
    if (lines != null) {
      movimientosGuardados.clear();
      for (String line : lines) {
        String[] valores = line.split(" ");
        ArrayList<Integer> movimientos = new ArrayList<Integer>();
        for (String valor : valores) {
          movimientos.add(Integer.parseInt(valor));
        }
        movimientosGuardados.add(movimientos);
      }
      println("Posiciones guardadas importadas exitosamente.");
      fabriMessage =("P  O  S  I  C  I  O  N  E  S    I  M  P  O  R  T  A  D  A  S    E  X  I  T  O  S  A  M  E  N  T  E");
    } else {
      println("No se encontró ningún archivo de posiciones guardadas.");
      fabriMessage =("N  O    S  E    E  N  C  O  N  T  R  Ó    N  I  N  G  Ú  N    A  R  C  H  I  V  O");
    }
  } else {
    println("No se seleccionó ningún archivo para importar.");
    fabriMessage =("N  O    S  E    S  E  L  E  C  C  I  O  N  Ó    A  R  C  H  I  V  O");
  }
}

void resetearPosiciones() {
  detenerMovimiento();
  movimientosGuardados.clear();
  println("Posiciones guardadas reseteadas. Ahora puedes empezar a grabar desde cero.");
  fabriMessage =("P  O  S  I  C  I  O  N  E  S    R  E  S  E  T  E  A  D  A  S");

}




void cerrar() {
  exit(); // Cerrar la aplicación
}


void actualizarPuertos() {
  cp5.remove("portDropdown"); // Eliminar el menú desplegable existente
  
  if (portList.length > 0) {
    // Si hay puertos disponibles, configurar el menú desplegable para seleccionar el puerto COM
    cp5.addDropdownList("portDropdown")
       .setPosition((int)(width * 0.03), (int)(height * 0.09))
       .setSize((int)(width * 0.18), (int)(height * 0.15)) // Aumentar tamaño de los cuadros
       .setBarHeight((int)(height * 0.05)) // Ajustar altura de la barra del menú desplegable
       .setItemHeight((int)(height * 0.05)) // Ajustar altura de los elementos del menú desplegable para centrar el texto verticalmente
       .setCaptionLabel("Selecciona el puerto")
       .setItems(portList)
       .setFont(createFont("Tahoma", 20));
    
    // Ajustar la alineación del texto para centrarlo en el botón
    textAlign(CENTER, CENTER);
    
    // Agregar eventos de ratón directamente al menú desplegable
    cp5.getController("portDropdown").setColorBackground(color(0, 0, 0)); // Cambiar a rojo cuando el cursor no esté encima
    cp5.getController("portDropdown").setColorForeground(color(100, 0, 20)); // Cambiar a verde cuando el cursor esté encima
    cp5.getController("portDropdown").setColorActive(color(20, 0, 100)); // Cambiar a amarillo cuando se presione
  } else {
    println("No hay puertos seriales disponibles.");
  }
}



boolean sonIguales(String[] arr1, String[] arr2) {
  if (arr1.length != arr2.length) {
    return false;
  }
  for (int i = 0; i < arr1.length; i++) {
    if (!arr1[i].equals(arr2[i])) {
      return false;
    }
  }
  return true;
}
