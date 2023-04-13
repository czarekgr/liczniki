#!/usr/bin/python3


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
csv_path = "raport.csv"

# Pobranie daty + 10 dni na wypadek konieczności robienia wcześniej, dzień ustawiony na 1
data = (date.today() + timedelta(days=10)).replace(day=1)

# data = '2022-12-01' # w razie importu starego itp

print(data)




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
        f=open(csv_path)
        cursor = conn.cursor()
        postgres_insert_query = """ INSERT INTO odczyty(data, adres, odczyt, status) VALUES(%s,%s,%s,%s) 
                                    ON CONFLICT ON CONSTRAINT odczyty_pkey
                                    DO
                                    UPDATE SET odczyt = %s, status = %s"""



        for linia in f:
            linia=linia.strip()
            pola = linia.split(";")
            if pola[0] == 'analog-value':
                adres = pola[1]
                odczyt = pola[3]
                status = pola[5]
                record_to_insert = (data, adres, odczyt, status, odczyt, status)
                cursor.execute(postgres_insert_query, record_to_insert)
                conn.commit()
        # liczniki co stoją jak chuj
        record_to_insert = (data, 'zdemontowany580', 6, 'Brak', 6, 'Zdemontowany')
        cursor.execute(postgres_insert_query, record_to_insert)
        conn.commit()
        record_to_insert = (data, 'zdemontowany600', 3194, 'Brak', 3194, 'Zdemontowany')
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
