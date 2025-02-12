CREATE DATABASE ПроектнаяОрганизация;
GO

USE ПроектнаяОрганизация;
GO

CREATE TABLE Отделы (
    ID_отдела INT IDENTITY(1,1) PRIMARY KEY,
    Название_отдела NVARCHAR(100) NOT NULL,
    Этаж INT CHECK (Этаж > 0 AND Этаж < 100),
    Телефон NVARCHAR(15) NOT NULL,
    Начальник_отдела NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE Сотрудники (
    ID_сотрудника INT IDENTITY(1,1) PRIMARY KEY,
    ФИО NVARCHAR(100) NOT NULL,
    Должность NVARCHAR(50) CHECK (Должность IN ('конструкторы', 'инженеры', 'техники', 'лаборанты', 'прочий обслуживающий персонал')),
    Номер_отдела INT FOREIGN KEY REFERENCES Отделы(ID_отдела) ON DELETE CASCADE,
    Пол NVARCHAR(1) CHECK (Пол IN ('М', 'Ж')),
    Адрес NVARCHAR(200) NOT NULL,
    Дата_рождения DATE NOT NULL
);
GO

CREATE TABLE Организации (
    ID_организации INT IDENTITY(1,1) PRIMARY KEY,
    Название_организации NVARCHAR(100) NOT NULL,
    Тип_деятельности NVARCHAR(100) NOT NULL,
    Страна NVARCHAR(50) NOT NULL,
    Город NVARCHAR(50) NOT NULL,
    Адрес NVARCHAR(200) NOT NULL,
    ФИО_директора NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE Договора (
    Номер_договора INT PRIMARY KEY,
    Дата_заключения DATE DEFAULT GETDATE(),
    ID_организации INT FOREIGN KEY REFERENCES Организации(ID_организации) ON DELETE CASCADE,
    Стоимость_договора DECIMAL(18,2) CHECK (Стоимость_договора > 0)
);
GO

CREATE TABLE Проектные_работы (
    ID_проектной_работы INT IDENTITY(1,1) PRIMARY KEY,
    Дата_начала DATE NOT NULL,
    Дата_завершения DATE NOT NULL,
    Номер_договора INT FOREIGN KEY REFERENCES Договора(Номер_договора) ON DELETE CASCADE,
    ID_отдела INT FOREIGN KEY REFERENCES Отделы(ID_отдела) ON DELETE CASCADE
);
GO