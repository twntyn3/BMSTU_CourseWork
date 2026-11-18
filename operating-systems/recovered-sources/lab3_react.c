#include <ntddk.h>  // основные типы и функции для kernel-драйвера ReactOS/Windows

#define LAB3_POOL_TAG '3baL'                 // тег для выделения памяти
#define LAB3_SystemProcessInformation 5      // класс запроса: информация о процессах

// Структура одной записи о процессе, которую возвращает ZwQuerySystemInformation
typedef struct _LAB3_SYSTEM_PROCESS_INFORMATION
{
    ULONG NextEntryOffset;                   // смещение до следующей записи процесса
    ULONG NumberOfThreads;                   // количество потоков процесса
    LARGE_INTEGER WorkingSetPrivateSize;     // служебное поле памяти
    ULONG HardFaultCount;                    // количество hard faults
    ULONG NumberOfThreadsHighWatermark;      // максимум потоков
    ULONGLONG CycleTime;                     // время CPU cycles
    LARGE_INTEGER CreateTime;                // время создания процесса
    LARGE_INTEGER UserTime;                  // время в user mode
    LARGE_INTEGER KernelTime;                // время в kernel mode
    UNICODE_STRING ImageName;                // имя процесса
    LONG BasePriority;                       // базовый приоритет процесса
    HANDLE UniqueProcessId;                  // PID процесса
    HANDLE InheritedFromUniqueProcessId;     // PID родительского процесса
    ULONG HandleCount;                       // количество handle
    ULONG SessionId;                         // ID сессии
    ULONG_PTR PageDirectoryBase;             // база каталога страниц
    SIZE_T PeakVirtualSize;                  // максимум виртуальной памяти
    SIZE_T VirtualSize;                      // текущий размер виртуальной памяти
    ULONG PageFaultCount;                    // количество page faults
    SIZE_T PeakWorkingSetSize;               // максимум working set
    SIZE_T WorkingSetSize;                   // текущий working set
    SIZE_T QuotaPeakPagedPoolUsage;          // максимум paged pool
    SIZE_T QuotaPagedPoolUsage;              // текущий paged pool
    SIZE_T QuotaPeakNonPagedPoolUsage;       // максимум nonpaged pool
    SIZE_T QuotaNonPagedPoolUsage;           // текущий nonpaged pool
    SIZE_T PagefileUsage;                    // использование pagefile
    SIZE_T PeakPagefileUsage;                // максимум pagefile
    SIZE_T PrivatePageCount;                 // количество приватных страниц
    LARGE_INTEGER ReadOperationCount;        // количество операций чтения
    LARGE_INTEGER WriteOperationCount;       // количество операций записи
    LARGE_INTEGER OtherOperationCount;       // другие операции ввода-вывода
    LARGE_INTEGER ReadTransferCount;         // объём прочитанных данных
    LARGE_INTEGER WriteTransferCount;        // объём записанных данных
    LARGE_INTEGER OtherTransferCount;        // объём других операций
} LAB3_SYSTEM_PROCESS_INFORMATION, *PLAB3_SYSTEM_PROCESS_INFORMATION;

// Объявляем ZwQuerySystemInformation вручную, потому что заголовки её не дали
NTKERNELAPI
NTSTATUS
NTAPI
ZwQuerySystemInformation(
    _In_ ULONG SystemInformationClass,       // что именно запрашиваем
    _Out_opt_ PVOID SystemInformation,       // буфер для результата
    _In_ ULONG SystemInformationLength,      // размер буфера
    _Out_opt_ PULONG ReturnLength            // нужный/возвращённый размер
);

DRIVER_UNLOAD Lab3Unload;                    // объявление функции выгрузки драйвера

static VOID
Lab3PrintProcessList(VOID)
{
    NTSTATUS Status;                         // статус результата kernel-функций
    ULONG BufferSize;                        // размер буфера под список процессов
    PVOID Buffer;                            // сам буфер
    PLAB3_SYSTEM_PROCESS_INFORMATION ProcessInfo; // текущая запись процесса

    BufferSize = 0;

    // Первый вызов: узнаём, сколько памяти нужно под список процессов
    Status = ZwQuerySystemInformation(
        LAB3_SystemProcessInformation,       // хотим список процессов
        NULL,                                // буфера пока нет
        0,                                   // размер буфера 0
        &BufferSize);                        // сюда система запишет нужный размер

    BufferSize = BufferSize + 4096;          // добавляем запас на случай новых процессов

    // Выделяем память в nonpaged pool, чтобы ядро могло безопасно ей пользоваться
    Buffer = ExAllocatePoolWithTag(
        NonPagedPool,                        // память не выгружается на диск
        BufferSize,                          // размер выделения
        LAB3_POOL_TAG);                      // тег выделения

    if (Buffer == NULL)                      // если память не выделилась
    {
        DbgPrint("Khromov LAB3: ExAllocatePoolWithTag failed\n");
        return;
    }

    RtlZeroMemory(Buffer, BufferSize);       // очищаем буфер от мусора

    // Второй вызов: уже реально получаем список процессов в Buffer
    Status = ZwQuerySystemInformation(
        LAB3_SystemProcessInformation,       // снова запрашиваем процессы
        Buffer,                              // буфер для результата
        BufferSize,                          // размер буфера
        &BufferSize);                        // фактически использованный размер

    if (!NT_SUCCESS(Status))                 // если запрос не удался
    {
        DbgPrint("Khromov LAB3: ZwQuerySystemInformation failed, status=0x%08lx\n",
                 Status);

        ExFreePool(Buffer);                  // освобождаем память перед выходом
        return;
    }

    DbgPrint("Khromov LAB3: process list begin\n");

    ProcessInfo = (PLAB3_SYSTEM_PROCESS_INFORMATION)Buffer; // первая запись процесса

    while (TRUE)                             // идём по всем записям процессов
    {
        ULONG Pid;                           // PID текущего процесса

        Pid = (ULONG)(ULONG_PTR)ProcessInfo->UniqueProcessId; // берём PID

        if (ProcessInfo->ImageName.Buffer != NULL) // если имя процесса есть
        {
            DbgPrint("Khromov LAB3: PID=%lu Name=%wZ\n",
                     Pid,
                     &ProcessInfo->ImageName);     // печатаем PID и Unicode-имя
        }
        else                                // если имени нет, обычно это Idle/System
        {
            DbgPrint("Khromov LAB3: PID=%lu Name=System/Idle\n",
                     Pid);
        }

        if (ProcessInfo->NextEntryOffset == 0) // если следующей записи нет
        {
            break;                          // заканчиваем цикл
        }

        // Переходим к следующей записи процесса по смещению NextEntryOffset
        ProcessInfo = (PLAB3_SYSTEM_PROCESS_INFORMATION)
            ((PUCHAR)ProcessInfo + ProcessInfo->NextEntryOffset);
    }

    DbgPrint("Khromov LAB3: process list end\n");

    ExFreePool(Buffer);                      // освобождаем выделенный буфер
}

VOID NTAPI
Lab3Unload(
    _In_ PDRIVER_OBJECT DriverObject         // объект драйвера
)
{
    UNREFERENCED_PARAMETER(DriverObject);    // параметр не используется

    DbgPrint("Khromov LAB3: driver unloaded\n");
}

NTSTATUS NTAPI
DriverEntry(
    _In_ PDRIVER_OBJECT DriverObject,        // объект драйвера
    _In_ PUNICODE_STRING RegistryPath        // путь в реестре
)
{
    UNREFERENCED_PARAMETER(RegistryPath);    // путь в реестре не используем

    DriverObject->DriverUnload = Lab3Unload; // назначаем функцию выгрузки

    DbgPrint("Khromov LAB3: driver loaded\n");

    Lab3PrintProcessList();                  // основная логика: вывести процессы

    return STATUS_SUCCESS;                   // сообщаем, что драйвер загрузился успешно
}

/*
В этом драйвере я получаю список процессов через ZwQuerySystemInformation 
с классом SystemProcessInformation. Первый вызов нужен, чтобы узнать размер буфера, 
затем я выделяю память через ExAllocatePoolWithTag, второй вызов заполняет буфер 
данными. Дальше я иду по записям через NextEntryOffset и вывожу UniqueProcessId и 
ImageName через DbgPrint. После обхода освобождаю буфер через ExFreePool.



*/