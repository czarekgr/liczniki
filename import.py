#!/usr/bin/python3


import tabula 
import psycopg2
import sys
import dateutil
from datetime import date , timedelta

# Dane do połączenia z bazą
baza = "liczniki"
host = "localhost"
user = "czarek"
password = "paselko"


# nazwy plików we/wy
pdf_path = "raport.pdf"
tsv_path = "raport.tsv"

# Pobranie daty + 10 dni na wypadek konieczności robienia wcześniej, dzień ustawiony na 1
data = (date.today() + timedelta(days=10)).replace(day=1)

# data = '2022-12-01' # w razie importu starego itp

print(data)



tabula.convert_into(pdf_path, tsv_path , pages="all", output_format="tsv", stream=True)

try:
#    conn_string = "host='localhost' dbname='liczniki' user='czarek' password='paselko'"
    conn_string = "host=%s dbname=%s user=%s password=%s " %(host,baza,user,password)
    print("Connecting to database\n        ->%s" % (conn_string))
    conn = psycopg2.connect(conn_string)
except psycopg2.OperationalError as e:
    print('Error: %s' % e)
    sys.exit(1)
else:
    print('Connected')
    try:
        f=open(tsv_path)
        cursor = conn.cursor()
        postgres_insert_query = """ INSERT INTO odczyty(data, adres, odczyt) VALUES(%s,%s,%s) 
                                    ON CONFLICT ON CONSTRAINT odczyty_pkey
                                    DO
                                    UPDATE SET odczyt = %s"""



        for linia in f:
            linia=linia.strip()
            pola = linia.split("\t")
            if pola[0] == '""' and pola[1] != "":
                adres = pola[1]
                odczyt = pola[3]
                record_to_insert = (data, adres, odczyt,odczyt)
                cursor.execute(postgres_insert_query, record_to_insert)
                conn.commit()
        # liczniki co stoją jak chuj
        record_to_insert = (data, 'zdemontowany580', 6,6)
        cursor.execute(postgres_insert_query, record_to_insert)
        conn.commit()
        record_to_insert = (data, 'zdemontowany600', 3194,3194)
        cursor.execute(postgres_insert_query, record_to_insert)
        conn.commit()
        

    except (Exception, psycopg2.Error) as error:
        print("Failed to insert record into mobile table", error)

finally:
    # closing database connection.
    if conn:
        cursor.close()
        conn.close()
        print("PostgreSQL connection is closed")
