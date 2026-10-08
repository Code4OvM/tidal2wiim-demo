from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parent
if len(sys.argv)!=2:
    raise SystemExit("Aufruf: python Modelle_rendern.py /pfad/zu/plantuml.jar")
jar=Path(sys.argv[1]).resolve()
if not jar.is_file(): raise SystemExit("plantuml.jar wurde nicht gefunden")
for fmt,folder in [("svg","SVG"),("png","PNG")]:
    (root/folder).mkdir(exist_ok=True)
    subprocess.run(["java","-Djava.awt.headless=true","-jar",str(jar),"-charset","UTF-8","-t"+fmt,"-o","../"+folder,*map(str,sorted((root/"PlantUML").glob("*.puml")))],check=True)
print("Alle Diagramme wurden in SVG/ und PNG/ erzeugt.")
