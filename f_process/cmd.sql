
create database if not exists db;
use db;
create table uczniowie (
	id_ucznia varchar(255) primary key,
	imie varchar(255),
	nazwisko varchar(255),
	klasa varchar(255)
);
set global local_infile = True;
load data local infile 'uczniowie.txt' into table uczniowie fields terminated by '\t' ignore 1 lines;
