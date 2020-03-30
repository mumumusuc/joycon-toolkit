import 'dart:core';
import 'package:vector_math/vector_math_64.dart';

/*
 *  A very simple Wavefront .OBJ parser.
 *  https://en.wikipedia.org/wiki/Wavefront_.obj_file
 */
class Model {
  List<double> vertices;
  List<double> normals;
  List<double> colors;
  List<int> indices;
  Map<String, List<double>> materials;

  Model() {
    vertices = List();
    normals = List();
    indices = List();
    colors = List();
    materials = {
      "frontal": [0.848100, 0.607500, 1.000000],
      "occipital": [1.000000, 0.572600, 0.392400],
      "parietal": [0.379700, 0.830900, 1.000000],
      "temporal": [1.000000, 0.930700, 0.468300],
      "cerebellum": [0.506300, 1.000000, 0.598200],
      "stem": [0.500000, 0.500000, 0.500000],
    };
  }

  /*
   *  Parses the object from a string.
   */
  void loadFromString(String string) {
    String material;
    List<String> lines = string.split("\n");
    lines.forEach((line) {
      // Parse a vertex
      if (line.startsWith("v ")) {
        var values = line.substring(2).split(" ");
        vertices.addAll([
          double.parse(values[0]),
          double.parse(values[1]),
          double.parse(values[2]),
        ]);
      }
      // Parse a material reference
      else if (line.startsWith("usemtl ")) {
        material = line.substring(7);
      }
      // Parse a face
      else if (line.startsWith("f ")) {
        var values = line.substring(2).split(" ");
        indices.addAll([
          int.parse(values[0].split("/")[0]) - 1,
          int.parse(values[1].split("/")[0]) - 1,
          int.parse(values[2].split("/")[0]) - 1,
        ]);
        //colors.addAll(materials[material]);
      }
    });
  }

  void loadFromString2(String string) {
    //String material;
    List<String> lines = string.split("\n");
    List<List<double>> points = [];
    List<List<int>> point_indices = [];
    lines.forEach((line) {
      // parse all vertices
      if (line.startsWith("v ")) {
        var values = line.substring(2).split(" ");
        points.add([
          double.parse(values[0]),
          double.parse(values[1]),
          double.parse(values[2])
        ]);
        //colors.addAll([0.75, 0.75, 0.39]);
      }
      // parse a material reference
      else if (line.startsWith("usemtl ")) {
        //material = line.substring(7);
      }
      // parse all faces
      else if (line.startsWith("f ")) {
        var values = line.substring(2).split(" ");
        var v1 = values[0].split("/");
        var v2 = values[1].split("/");
        var v3 = values[2].split("/");
        point_indices.add([
          int.tryParse(v1[0]),
          int.tryParse(v2[0]),
          int.tryParse(v3[0]),
        ]);
        /*
        normal_indices.addAll([
          int.tryParse(v1[2]),
          int.tryParse(v2[2]),
          int.tryParse(v3[2]),
        ]);
        */
      }
    });
    point_indices.forEach((e) {
      var p0 = points[e[0] - 1];
      var p1 = points[e[1] - 1];
      var p2 = points[e[2] - 1];
      var a = Vector3.array(p1) - Vector3.array(p0);
      var b = Vector3.array(p2) - Vector3.array(p0);
      Vector3 c = Vector3.zero();
      cross3(a, b, c);
      vertices.addAll(p0);
      vertices.addAll(p1);
      vertices.addAll(p2);
      normals.addAll(c.storage);
      normals.addAll(c.storage);
      normals.addAll(c.storage);
      colors.addAll([1.000000, 0.572600, 0.392400,1.000000, 0.572600, 0.392400,1.000000, 0.572600, 0.392400]);
    });
  }
}
