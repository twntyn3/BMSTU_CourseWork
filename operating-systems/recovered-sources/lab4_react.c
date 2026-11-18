#include <ntddk.h>  // основные типы и функции для kernel-драйвера ReactOS/Windows

#define LAB4_PAGE_COUNT_TOTAL 10      // всего резервируем 10 виртуальных страниц
#define LAB4_PAGE_COUNT_COMMIT 5      // физически обеспечиваем первые 5 страниц
#define LAB4_PAGE_SIZE 0x1000         // размер страницы: 0x1000 = 4096 байт

// Базовый адрес области PTE в 32-битной системе
#define LAB4_PTE_BASE 0xC0000000

// Макрос вычисляет адрес PTE для конкретного виртуального адреса va
#define LAB4_PTE_ADDRESS(va) \
    ((PULONG)(LAB4_PTE_BASE + ((((ULONG_PTR)(va)) >> 12) * sizeof(ULONG))))

// Объявляем ZwAllocateVirtualMemory вручную, потому что заголовки её не дали
NTKERNELAPI
NTSTATUS
NTAPI
ZwAllocateVirtualMemory(
    _In_ HANDLE ProcessHandle,       // процесс, в котором выделяем память
    _Inout_ PVOID *BaseAddress,      // базовый адрес области памяти
    _In_ ULONG_PTR ZeroBits,         // ограничения на старшие биты адреса, у нас 0
    _Inout_ PSIZE_T RegionSize,      // размер области памяти
    _In_ ULONG AllocationType,       // тип выделения: MEM_RESERVE или MEM_COMMIT
    _In_ ULONG Protect              // права доступа, у нас PAGE_READWRITE
);

// Объявляем ZwFreeVirtualMemory вручную
NTKERNELAPI
NTSTATUS
NTAPI
ZwFreeVirtualMemory(
    _In_ HANDLE ProcessHandle,       // процесс, в котором освобождаем память
    _Inout_ PVOID *BaseAddress,      // адрес освобождаемой области
    _Inout_ PSIZE_T RegionSize,      // размер области
    _In_ ULONG FreeType              // тип освобождения, у нас MEM_RELEASE
);

DRIVER_UNLOAD Lab4Unload;            // объявление функции выгрузки драйвера

// Функция выводит информацию о первых 5 страницах: VA, PA и PTE
static VOID
Lab4PrintPageInfo(PVOID BaseAddress)
{
    ULONG i;                         // номер текущей страницы

    DbgPrint("Khromov LAB4: page info begin\n");

    // Проходим по первым 5 страницам
    for (i = 0; i < LAB4_PAGE_COUNT_COMMIT; i++)
    {
        PUCHAR PageAddress;          // виртуальный адрес текущей страницы
        PHYSICAL_ADDRESS PhysicalAddress; // физический адрес страницы
        ULONG PteValue;              // значение PTE

        // Получаем адрес i-й страницы: base + i * 4096
        PageAddress = (PUCHAR)BaseAddress + i * LAB4_PAGE_SIZE;

        /*
         * Обращаемся к странице записью.
         * Это нужно, чтобы страница точно получила физическую память.
         */
        PageAddress[0] = (UCHAR)i;

        // Получаем физический адрес по виртуальному адресу
        PhysicalAddress = MmGetPhysicalAddress(PageAddress);

        // Получаем значение PTE для данной виртуальной страницы
        PteValue = *LAB4_PTE_ADDRESS(PageAddress);

        // Печатаем номер страницы
        DbgPrint("Khromov LAB4: page %lu\n", i);

        // Печатаем виртуальный адрес
        DbgPrint("Khromov LAB4:   VA  = 0x%p\n", PageAddress);

        // Печатаем физический адрес: HighPart + LowPart
        DbgPrint("Khromov LAB4:   PA  = 0x%08lx%08lx\n",
                 PhysicalAddress.HighPart,
                 PhysicalAddress.LowPart);

        // Печатаем значение PTE
        DbgPrint("Khromov LAB4:   PTE = 0x%08lx\n", PteValue);
    }

    DbgPrint("Khromov LAB4: page info end\n");
}

// Основная функция лабораторной работы №4
static NTSTATUS
Lab4RunMemoryTest(VOID)
{
    NTSTATUS Status;                 // статус выполнения kernel-функций
    PVOID BaseAddress;               // базовый адрес зарезервированной области
    SIZE_T ReserveSize;              // размер области для резерва
    SIZE_T CommitSize;               // размер области для коммита
    PVOID CommitAddress;             // адрес, с которого коммитим память
    SIZE_T FreeSize;                 // размер при освобождении памяти

    BaseAddress = NULL;              // NULL значит: пусть система сама выберет адрес
    ReserveSize = LAB4_PAGE_COUNT_TOTAL * LAB4_PAGE_SIZE; // 10 * 4096 байт

    DbgPrint("Khromov LAB4: start\n");

    // 1. Резервируем 10 страниц виртуальной памяти
    Status = ZwAllocateVirtualMemory(
        NtCurrentProcess(),          // выделяем память в текущем процессе
        &BaseAddress,                // сюда вернётся базовый адрес
        0,                           // ZeroBits не используем
        &ReserveSize,                // размер: 10 страниц
        MEM_RESERVE,                 // только резерв виртуальных адресов
        PAGE_READWRITE);             // права: чтение и запись

    // Проверяем, получилось ли зарезервировать память
    if (!NT_SUCCESS(Status))
    {
        DbgPrint("Khromov LAB4: MEM_RESERVE failed, status=0x%08lx\n", Status);
        return Status;
    }

    DbgPrint("Khromov LAB4: reserved 10 virtual pages\n");
    DbgPrint("Khromov LAB4: base virtual address = 0x%p\n", BaseAddress);

    // 2. Готовим коммит первых 5 страниц
    CommitAddress = BaseAddress;     // начинаем коммитить с начала зарезервированной области
    CommitSize = LAB4_PAGE_COUNT_COMMIT * LAB4_PAGE_SIZE; // 5 * 4096 байт

    // Коммитим первые 5 страниц
    Status = ZwAllocateVirtualMemory(
        NtCurrentProcess(),          // текущий процесс
        &CommitAddress,              // адрес начала коммита
        0,                           // ZeroBits не используем
        &CommitSize,                 // размер: 5 страниц
        MEM_COMMIT,                  // физически обеспечиваем память
        PAGE_READWRITE);             // чтение и запись

    // Если коммит не удался, освобождаем уже зарезервированную область
    if (!NT_SUCCESS(Status))
    {
        DbgPrint("Khromov LAB4: MEM_COMMIT failed, status=0x%08lx\n", Status);

        FreeSize = 0;                // для MEM_RELEASE размер должен быть 0
        ZwFreeVirtualMemory(
            NtCurrentProcess(),
            &BaseAddress,
            &FreeSize,
            MEM_RELEASE);            // освобождаем весь резерв

        return Status;
    }

    DbgPrint("Khromov LAB4: committed first 5 pages\n");

    // 3. Выводим информацию о первых 5 страницах
    Lab4PrintPageInfo(BaseAddress);

    // 4. Освобождаем всю выделенную область
    FreeSize = 0;                    // для MEM_RELEASE размер равен 0

    Status = ZwFreeVirtualMemory(
        NtCurrentProcess(),          // текущий процесс
        &BaseAddress,                // адрес области
        &FreeSize,                   // размер 0 для MEM_RELEASE
        MEM_RELEASE);                // полностью освобождаем область

    // Проверяем, освободилась ли память
    if (!NT_SUCCESS(Status))
    {
        DbgPrint("Khromov LAB4: MEM_RELEASE failed, status=0x%08lx\n", Status);
        return Status;
    }

    DbgPrint("Khromov LAB4: memory released\n");
    DbgPrint("Khromov LAB4: end\n");

    return STATUS_SUCCESS;           // лабораторная логика выполнена успешно
}

// Функция выгрузки драйвера
VOID NTAPI
Lab4Unload(
    _In_ PDRIVER_OBJECT DriverObject // объект драйвера
)
{
    UNREFERENCED_PARAMETER(DriverObject); // параметр есть, но мы его не используем

    DbgPrint("Khromov LAB4: driver unloaded\n");
}

// Главная функция драйвера, вызывается при загрузке
NTSTATUS NTAPI
DriverEntry(
    _In_ PDRIVER_OBJECT DriverObject,     // объект драйвера
    _In_ PUNICODE_STRING RegistryPath     // путь в реестре
)
{
    UNREFERENCED_PARAMETER(RegistryPath); // путь в реестре не используем

    DriverObject->DriverUnload = Lab4Unload; // назначаем функцию выгрузки

    DbgPrint("Khromov LAB4: driver loaded\n");

    return Lab4RunMemoryTest();           // запускаем основную логику lab4
}



//В этом драйвере сначала через ZwAllocateVirtualMemory 
//с флагом MEM_RESERVE резервируются 10 страниц виртуальной памяти. 
//Затем через эту же функцию, но с флагом MEM_COMMIT, коммитятся первые 5 страниц. 
//После этого для каждой из 5 страниц я записываю байт, чтобы страница 
//точно получила физическую память, получаю физический адрес через 
//MmGetPhysicalAddress и читаю значение PTE через вычисленный адрес 
//записи таблицы страниц. В конце вся область освобождается через 
//ZwFreeVirtualMemory с флагом MEM_RELEASE.