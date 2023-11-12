// Importaciones de bibliotecas necesarias para el proyecto.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:model_viewer_plus/model_viewer_plus.dart';

// Punto de entrada principal de la aplicación.
void main() => runApp(const MyApp());

// -------------------------- MyApp Class --------------------------

// Clase principal de la aplicación.
class MyApp extends StatelessWidget {
  // Constructor constante con key opcional.
  const MyApp({Key? key}) : super(key: key);

  // Método que construye la interfaz de usuario de la aplicación.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Aplicación',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(
            //Pa los temas de la UT
            0xFF00AB84,
            {
              50: Color(0xFFE0F2F1),
              100: Color(0xFFB2DFDB),
              200: Color(0xFF80CBC4),
              300: Color(0xFF4DB6AC),
              400: Color(0xFF26A69A),
              500: Color(0xFF009688),
              600: Color(0xFF00897B),
              700: Color(0xFF00796B),
              800: Color(0xFF00695C),
              900: Color(0xFF004D40),
            },
          ),
        ),
        appBarTheme: const AppBarTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(18),
            ),
          ),
        ),
      ),
      home: const ZonasPage(), // Página inicial de la aplicación
    );
  }
}

// ------------------- ZonaArqueologica Class ---------------------

class ZonaArqueologica {
  final int id;
  final String nombre;
  final String descripcion;
  final String estado;
  final String historia;
  final String modelo;
  final List<String> imagenes;
  final double nodoX; // Coordenada X del nodo
  final double nodoY; // Coordenada Y del nodo

  ZonaArqueologica({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
    required this.historia,
    required this.modelo,
    required this.imagenes,
    required this.nodoX,
    required this.nodoY,
  });

  factory ZonaArqueologica.fromJson(Map<String, dynamic> json) {
    return ZonaArqueologica(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      estado: json['estado'],
      historia: json['historia'],
      modelo: json['modelo'],
      imagenes:
          List<String>.from(json['imagenes']), // Convertir a lista de strings
      nodoX: json['nodoX'].toDouble(),
      nodoY: json['nodoY'].toDouble(),
    );
  }
}

// Definir una lista para almacenar los rectángulos y IDs de zona
List<NodeRect> nodeRects = [];

class NodeRect {
  final Rect rect;
  final int zonaId;

  NodeRect(this.rect, this.zonaId);
}

// ------------ Validacion compatibilidad dispositivos -------------------
Widget getSubtitle(ZonaArqueologica zona) {
  if (!kIsWeb && Platform.isAndroid) {
    return Text(zona.descripcion);
  } else {
    return const Text("No es compatible");
  }
}

// ------------------- Primera mitad de pantalla ---------------------

class ModelViewPage extends StatelessWidget {
  final ZonaArqueologica zona;

  const ModelViewPage({Key? key, required this.zona}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas Arqueológicas'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF00AB84), // Cambio aquí
              child: const Center(
                child: Text("Trazado/Nodos aquí"),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ZonaArqueologica>>(
              future: cargarZonas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final List<ZonaArqueologica> zonas = snapshot.data!;
                  return ListView.builder(
                    itemCount: zonas.length,
                    itemBuilder: (context, index) {
                      final zona = zonas[index];
                      if (selectedState == 'Todos' ||
                          zona.estado == selectedState) {
                        // Nuevo: Filtrado por estado
                        return ListTile(
                          title: Text(zona.nombre),
                          subtitle: getSubtitle(zona),
                          onTap: () => _showZonaDetails(context, zona),
                        );
                      }
                      return const SizedBox
                          .shrink(); //Si no coincide con el estado, no mostrar nada
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Codigo para los nodos (puntos)
class MapPainter extends CustomPainter {
  final List<ZonaArqueologica> zonas;
  final String selectedState;
  final Offset? touchPosition;
  final Offset? touchedNodePosition;

  const MapPainter(this.zonas, this.selectedState, this.touchPosition,
      this.touchedNodePosition);

  @override
  void paint(Canvas canvas, Size size) {
    nodeRects.clear(); // Limpiar la lista antes de rellenarla
    for (var i = 0; i < zonas.length; i++) {
      final node = Offset(
        size.width * (1.0 - zonas[i].nodoX),
        size.height * zonas[i].nodoY,
      );

      // Crear un rectángulo alrededor del nodo
      final nodeRect = Rect.fromCircle(center: node, radius: 20);
      // Almacenar el rectángulo y el id de la zona
      nodeRects.add(NodeRect(nodeRect, zonas[i].id));
      final textSpan = TextSpan(
        text: zonas[i].nombre,
        style: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 8.0,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, node + Offset(-textPainter.width / 2, -20));

      // Dibujar un círculo morado en cada nodo
      final touchedNodeCirclePaint = Paint()
        ..color = const Color.fromARGB(255, 210, 65, 65)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node, 8, touchedNodeCirclePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is MapPainter) {
      return oldDelegate.touchPosition != touchPosition ||
          oldDelegate.touchedNodePosition != touchedNodePosition ||
          oldDelegate.selectedState != selectedState;
    }
    return true;
  }
}

//Filtrar por defecto todas las zonas
ValueNotifier<String> selectedStateNotifier = ValueNotifier<String>('Todos');

class ZonasPage extends StatefulWidget {
  const ZonasPage({Key? key}) : super(key: key);

  @override
  ZonasPageState createState() => ZonasPageState();
}

String selectedState = 'Todos';
Future<List<ZonaArqueologica>> cargarZonasFiltradas() async {
  final String response =
      await rootBundle.loadString('assets/zonas_arqueologicas.json');
  final data = json.decode(response) as Map<String, dynamic>;
  final List<ZonaArqueologica> todasLasZonas = (data['zonas'] as List)
      .map((item) => ZonaArqueologica.fromJson(item))
      .toList();

  if (selectedState == 'Todos') {
    return todasLasZonas; // Si el estado es 'Todos', devuelve todas las zonas
  } else {
    // Filtra las zonas basadas en el estado seleccionado
    return todasLasZonas.where((zona) => zona.estado == selectedState).toList();
  }
}

// ---------------------- Segunda mitad de pantalla --------------------
Future<List<ZonaArqueologica>> cargarZonas() async {
  //cargar la informacion del json
  final String response =
      await rootBundle.loadString('assets/zonas_arqueologicas.json');
  final data = json.decode(response) as Map<String, dynamic>;
  final List<ZonaArqueologica> zonas = (data['zonas'] as List)
      .map((item) =>
          ZonaArqueologica.fromJson(item)) //la lista de zonas sacadas del json
      .toList();
  return zonas;
}

void _showZonaDetails(BuildContext context, ZonaArqueologica zona) {
  final colorScheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20.0), // sirve para redondear las esquinas
        ),
        title: Text(
          zona.nombre,
          style: TextStyle(
              color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0), // Agregar padding
          child: Column(
            children: <Widget>[
              CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    enlargeCenterPage: true,
                    autoPlay: false,
                    aspectRatio: 16 / 9,
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enableInfiniteScroll: false,
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    viewportFraction: 0.8,
                  ),
                  items: zona.imagenes.map((imagePath) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Image.asset(imagePath),
                        );
                      },
                    );
                  }).toList()),
              const SizedBox(height: 10),
              Text('Descripción: ${zona.descripcion}'),
              const SizedBox(height: 10),
              Text('Estado: ${zona.estado}'),
              const SizedBox(height: 10),
              Text('Historia: ${zona.historia}'),
            ],
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, // Color del botón
              foregroundColor: colorScheme.onPrimary, // Color del texto
            ),
            child: const Text('Cerrar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class ZonasPageState extends State<ZonasPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<List<ZonaArqueologica>> futureZonas;
  Offset? touchPosition;
  Offset? touchedNodePosition;

  @override
  void initState() {
    super.initState();
    futureZonas = cargarZonasFiltradas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Zonas Arqueológicas'),
        backgroundColor: const Color(0xFF00AB84),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Filtrar por: ", style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  // Dropdown para seleccionar el estado
                  value: selectedState,
                  items: <String>[
                    'Todos',
                    'Yucatan',
                    'Quintana Roo',
                    'Campeche'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedState = newValue!;
                      futureZonas =
                          cargarZonasFiltradas(); // esto actualiza la lista de zonas
                    });
                  },
                ),
              ],
            ),
            Expanded(
              flex: 2,
              child: FutureBuilder<List<ZonaArqueologica>>(
                future: futureZonas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final List<ZonaArqueologica> zonas = snapshot.data!;
                    return InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: 0.5,
                      maxScale: 2.0,
                      child: GestureDetector(
                        onTapUp: (TapUpDetails details) {
                          setState(() {
                            touchPosition = details
                                .localPosition; // Actualizar la posición de toque
                          });
                          _handleTap(details, context);
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset('assets/img/peninsula2.jpg',
                                fit: BoxFit.cover),
                            CustomPaint(
                              painter: MapPainter(zonas, selectedState,
                                  touchPosition, touchedNodePosition),
                              child: Container(),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            Expanded(
              flex: 3,
              child: FutureBuilder<List<ZonaArqueologica>>(
                future: futureZonas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final List<ZonaArqueologica> zonas = snapshot.data!;
                    return ListView.builder(
                      itemCount: zonas.length,
                      itemBuilder: (context, index) {
                        final zona = zonas[index];
                        return Card(
                          margin: const EdgeInsets.all(10.0),
                          elevation: 5.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12.0),
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(
                                zona.imagenes.isNotEmpty
                                    ? zona.imagenes[0]
                                    : 'assets/placeholder.png',
                              ),
                            ),
                            title: Text(zona.nombre),
                            subtitle: getSubtitle(zona),
                            trailing: IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => _showZonaDetails(context, zona),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

//Funciones que controlan los nodos en el mapa
  void _handleTap(TapUpDetails details, BuildContext context) async {
    var touchPosition = details.localPosition;
    final zonas = await cargarZonasFiltradas();

    double closestDistance = double.infinity;
    ZonaArqueologica? closestZona;

    final Size size = MediaQuery.of(_scaffoldKey.currentContext!).size;

    for (var nodeRect in nodeRects) {
      if (nodeRect.rect.contains(touchPosition)) {
        // Encontrado un nodo que fue tocado
        final zonaTocada =
            zonas.firstWhere((zona) => zona.id == nodeRect.zonaId);
        _showModelViewerDialog(_scaffoldKey.currentContext!, zonaTocada);

        return; // Salir de la función una vez que encuentres el nodo tocado
      }
    }

    for (int i = 0; i < zonas.length; i++) {
      final nodePosition = Offset(
        size.width * (1.0 - zonas[i].nodoX),
        size.height * zonas[i].nodoY,
      );

      final distance = (touchPosition - nodePosition).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestZona = zonas[i];
      }
    }
// area de toque para cada nodo en este caso de 50 px
    if (closestDistance < 50 && closestZona != null) {
      _showModelViewerDialog(_scaffoldKey.currentContext!, closestZona);
    }
  }

// Este es el diálogo que muestra el modelo al tocar un nodo
  void _showModelViewerDialog(BuildContext context, ZonaArqueologica zona) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(zona.nombre),
          content: SizedBox(
            height: MediaQuery.of(context).size.height *
                0.5, // o cualquier otra altura deseada
            child: ModelViewer(
              src: zona.modelo,
              alt: "Un modelo 3D de ${zona.nombre}",
              ar: true,
              autoRotate: true,
              cameraControls: true,
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
