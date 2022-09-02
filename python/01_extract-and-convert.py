#!/usr/bin/python3
import os
import sys
import ast
import glob
import spatialite
import re

##### extracts data from osm original format and saves it as sqlite databases 
##### _______________________________________
    
#ORIG = "01_raw_osm"
ORIG = str(sys.argv[1]).split(" ")[0]  ## folder that holds original osm data
print(ORIG)
#COUNTRIES =['us-west'] #'bosnia'#'bulgaria'#'croatia'#'kosovo'#'montenegro'#'macedonia'#'romania' #'serbia'#'slovenia'#'czech-republic'#'poland' #'india' #'us-west' #'us-south' #'us-pacific' #'us-northeast' #'us-midwest' #'us' #"switzerland" #"denmark" #"belgium" #"netherlands" #"ireland_and_northern_ireland2 #"great_britain" #"japan"  #"luxemburg", #"austria", "germany", 
r = str(sys.argv[2]).split(" ")[0]  ## countries to be computed 
c = ast.literal_eval(r)
COUNTRIES = [n.strip() for n in c]
OUTDIR= str(sys.argv[3]).split(" ")[0]
MERGEDDIR = os.path.join(OUTDIR, 'merged')
DBDIR = os.path.join(OUTDIR, 'db')


DATASETS = {
'highway': {'query': 'highway=*', 'type': ['lines'], 'fields': ['other_tags:surface', 'other_tags:tunnel', 'other_tags:bridge'], 'calculated': ['breite']},
'railway': {'query': 'railway=*', 'type': ['lines'], 'fields': ['other_tags:railway', 'other_tags:tunnel', 'other_tags:bridge'], 'calculated': ['breite']},
'parking': {'query': 'amenity=parking', 'type': ['multipolygons'], 'fields': ['other_tags:parking', 'other_tags:surface']},
'runway':  {'query': 'aeroway=runway', 'type': ['lines'], 'fields': ['other_tags:surface'], 'calculated': ['breite']},
'taxiway': {'query': 'aeroway=taxiway', 'type': ['lines'], 'fields': ['other_tags:surface'], 'calculated': ['breite']},
'subwayplatform':  {'query': ['railway=platform', 'subway=yes'], 'type': ['lines']},
'apron':  {'query': 'aeroway=apron', 'type': ['multipolygons'], 'fields': ['other_tags:surface']},
}


def get_columns_from_table(db, table_name):
    columns = db.execute(f'select * from pragma_table_info("{table_name}")')
    column_names = []

    for nr, name, datatype, _, _, _ in columns:
        column_names.append(name)

    return column_names


def makedirs_if_needed(directory_name):
    if not os.path.exists(directory_name):
        os.makedirs(directory_name, exist_ok=True)

def add_missing_text_fields(db, table, fields):
    
    column_names = get_columns_from_table(db=db, table_name=table)
    
    for field in fields:
        if ":" in field:
            _, field = field.split(":")
            
        if not field in column_names:
            print(f"creating {field} on table {table} ")
            db.execute(f'ALTER TABLE {table} ADD COLUMN {field} TEXT;')
            db.commit()

def add_missing_calc_fields(db, table, fields):
    column_names = get_columns_from_table(db=db, table_name=table)
    
    for field in fields:
        if field == "breite":
            if field not in column_names:
                print(f"creating {field} on table {table}")
                db.execute(f'ALTER TABLE {table} ADD COLUMN breite REAL;')

            if "breite_halb" not in column_names:
                statement = f'ALTER TABLE {table} ADD COLUMN breite_halb REAL;'
                db.execute(statement)
                
            db.commit()

def parse_other_tags(tag):
    values = {}
    
    for item in re.split(r',(?=")', tag):
        try:
            key, value = item.split("=>")
            key = key.replace('"', "")
            value = value.replace('"', "")
            values[key] = value
        except ValueError:
            print(f"ERROR IN OTHER_TAGS '{tag}': ERROR IN ITEM {item}, ignoring")

    return values

def update_fields(db, table, ogc_fid, fields, values):
    for field in fields:
        if ":" in field:
            source, field = field.split(":")
        else:
            source = field
                            
        if source == "other_tags":
            if field in values:
                statement = f"update {table} set {field} = '{values[field]}' where ogc_fid = {ogc_fid};"
                db.execute(statement)
        else:
            print(f"field update from {source} currently not supported")


def convert_width(string):
    if string is None:
        return None
            
    width = string
    if  isinstance(string, str):
        if string.endswith(("m", "meter", 'metres', 'meters')):
            width = string.split("m")[0]
        if string.endswith(("M", "Meter", 'Metres', 'Meters')):
            width = string.split("M")[0]
    try:
        width = float(width)
    except ValueError:
        print("WEIRD WITDH", width)
        return None
        
    return width 
    

def update_calc_fields(db, table, ogc_fid, calc_fields, values):
    for field in calc_fields:
        if field != "breite":
            print(f"unknown calculated field {field}")
            continue

        width = values.get('width', None)

        if width is None:
            continue
            
        width = convert_width(width)
        if width is None:
            continue

        statement = f"update {table} set breite = '{width}' where ogc_fid = {ogc_fid};"
        db.execute(statement)
        statement = f"update {table} set breite_halb = '{width/2.0}' where ogc_fid = {ogc_fid};"
        db.execute(statement)
                        

class DataSet:
    def __init__(self, name, query, geometry_types, fields, calculated_fields=None):
        self.dataset = name
        self.query = query
        self.geometry_types = geometry_types
        self.fields = fields
        self.calculated_fields = calculated_fields

    def extract(self, infile, outfile, query=None):
        if query is None:
            query = self.query
        cmd = f"osmium tags-filter {infile} w/{query} -o {outfile}"
     
        if not os.path.exists(outfile):
            print(cmd)   
            os.system(cmd)

    def extract_dir(self, country):
        return os.path.join(OUTDIR, 'extracted', self.dataset, country)


    def extract_for_country(self, country):
        in_dir = os.path.join(ORIG, country)
        files = glob.glob(os.path.join(in_dir, "*.pbf"))
        out_dir = self.extract_dir(country)
        makedirs_if_needed(out_dir)
        
        for filename in files:
            name = filename.split(".")[0]
            name = os.path.split(name)[-1]
    
            outfile = os.path.join(out_dir, f"{country}-{name}-{self.dataset}.osm.pbf")
            infile = filename
            
            if isinstance(self.query, str):
                self.extract(infile, outfile)
            elif isinstance(self.query, list):
                for query in self.query:
                    query_nice = query.replace("=", "-")

                    # CREATE TEMPORARY FILES EXCEPT FOR THE LAST STEP
                    if query == self.query[-1]:
                        infix = ""
                    else:
                        infix = ".TMP"
                        
                    outfile = os.path.join(out_dir, f"{country}-{name}-{self.dataset}-{query_nice}.osm{infix}.pbf")
                    self.extract(infile, outfile, query)
                    infile = outfile
                    
    def merge_for_country(self, country):
        outfile = os.path.join(MERGEDDIR, f"{country}-{self.dataset}.osm.pbf")
        in_dir = self.extract_dir(country)
        files = list(glob.glob(os.path.join(in_dir, "*.osm.pbf")))

        cmd = f"osmium merge {' '.join(files)} -o {outfile}"
        if not os.path.exists(outfile):
            os.system(cmd)

    def field_magic(self, country):
        dbfile = os.path.join(DBDIR, f"{country}-{self.dataset}.sqlite")
        print(dbfile)
        with spatialite.connect(dbfile) as db:
            for geom in self.geometry_types:
                
                add_missing_text_fields(db, table=geom, fields=self.fields)
                add_missing_calc_fields(db, table=geom, fields=self.calculated_fields)

                records = db.execute(f'select ogc_fid, other_tags from {geom}')

                for record in records:
                    fid, other_tags = record

                    if not other_tags:
                        continue
                        
                    values = parse_other_tags(other_tags)
                    update_fields(db, table=geom, ogc_fid=fid, fields=self.fields, values=values)
                    update_calc_fields(db, table=geom, ogc_fid=fid, calc_fields=self.calculated_fields, values=values)

                db.commit()
                
    def modifyRoadDB(self, country):
        dbfile = os.path.join(DBDIR, f"{country}-highway.sqlite")
        print(dbfile)
        with spatialite.connect(dbfile) as db:
            db.execute(f'ALTER TABLE lines ADD category varchar(30);')
            db.execute(f'UPDATE lines SET category = highway;')
			
            db.execute(f'UPDATE lines SET category = "track_1" WHERE (highway = "track") AND (other_tags like "%grade1%");')
            db.execute(f'UPDATE lines SET category = "track_2" WHERE (highway = "track") AND (other_tags like "%grade2%");')
            db.execute(f'UPDATE lines SET category = "track_3" WHERE (highway = "track") AND (other_tags like "%grade3%");')
            db.execute(f'UPDATE lines SET category = "track_4" WHERE (highway = "track") AND (other_tags like "%grade4%");')
            db.execute(f'UPDATE lines SET category = "track_5" WHERE (highway = "track") AND (other_tags like "%grade5%");')
            db.execute(f'UPDATE lines SET category = "track_na" WHERE (highway = "track") AND (category = "track")')
            
            db.commit()


def convert_osm_pbf_to_db(indir, outdir, code):
    for infile in glob.glob(os.path.join(indir, "*.osm.pbf")):
        fn = os.path.split(infile)[-1].split(".")[0]
        outfile = os.path.join(outdir, f"{fn}.sqlite")
        
        if not os.path.exists(outfile):
            cmd = f"ogr2ogr -t_srs {code} -f 'SQLITE' -dsco SPATIALITE=YES {outfile} {infile}"
            os.system(cmd)
            print(cmd)


def main():
    # make dirs
    makedirs_if_needed(DBDIR)
    makedirs_if_needed(MERGEDDIR)

    # read datasets from definition
    datasets = []
    for name in DATASETS:
        ds = DATASETS[name]
        datasets.append(DataSet(name, query=ds.get('query', ""), geometry_types=ds.get('type', []),
                                fields=ds.get('fields', []), calculated_fields=ds.get('calculated', [])))


    # EXTRACT
    for country in COUNTRIES:
        for ds in datasets:
            ds.extract_for_country(country)
        
    # MERGE
    for country in COUNTRIES:
        for ds in datasets:    
            ds.merge_for_country(country)


    # DB-IZE and REPROJECT
    convert_osm_pbf_to_db(indir=MERGEDDIR, outdir=DBDIR, code="EPSG:3035")

    # FIELD CALCULATIONS

    for country in COUNTRIES:
        for ds in datasets:    
            ds.field_magic(country)
      
    for country in COUNTRIES:
        datasets[0].modifyRoadDB(country)
        
        
if __name__ == '__main__':
    main()

                    
                    
                        
                        
                
                

