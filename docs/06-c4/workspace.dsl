workspace "ИС Умный дом" "Учебная модель архитектуры" {
  model {
    resident = person "Жилец" "Управляет устройствами и сценариями, получает уведомления"
    tech = person "Техник" "Обслуживает устройства и смотрит журнал сбоев"

    tg = softwareSystem "Телеграм-бот" "Внешний канал команд и уведомлений" "External"
    police = softwareSystem "Полиция" "Принимает аварийные сигналы" "External"
    devices = softwareSystem "Устройства умного дома" "Свет, замки, климат, датчики" "External"

    smartHome = softwareSystem "ИС «Умный дом»" "Управляет устройствами, сценариями, доступом и уведомлениями" {
      api = container "Backend API (Контроллер)" "Команды, сценарии, права и оркестрация" "Kotlin 2.x, Spring Boot" {
        commandController = component "CommandController" "Принимает команды и оркестрирует сценарий" "Kotlin, Spring MVC"
        policyService = component "PolicyService" "Проверяет роли, права и эскалацию" "Kotlin"
        deviceService = component "DeviceService" "Проверяет доступность и публикует команды" "Kotlin"
        journalService = component "JournalService" "Публикует события журнала" "Kotlin"
        notificationService = component "NotificationService" "Формирует уведомления" "Kotlin"
      }
      friday = container "Голосовой модуль «Пятница»" "Распознаёт голос и передаёт команду" "Python 3.12, FastAPI, ML"
      mqtt = container "Брокер сообщений MQTT" "Команды устройствам и показания датчиков" "Eclipse Mosquitto" "Queue"
      eventBus = container "Очередь событий" "Асинхронные события журнала и уведомлений" "RabbitMQ" "Queue"
      journalWorker = container "Обработчик журнала" "Читает события из очереди и пишет в БД" "Kotlin, Spring Boot"
      notification = container "Сервис уведомлений" "Формирует и доставляет уведомления" "Kotlin, Spring Boot"
      db = container "БД «Журнал»" "События, команды, статусы и права" "PostgreSQL 16" "Database"
    }

    resident -> tg "Отправляет команды и получает статусы" "HTTPS"
    tg -> api "Передаёт команды" "HTTPS"
    tg -> resident "Показывает результат" "Telegram"
    tech -> api "Обслуживает устройства, смотрит журнал" "HTTPS"
    friday -> api "Передаёт распознанную команду" "HTTPS"
    api -> db "Читает права и статусы, пишет команды" "JDBC"
    api -> mqtt "Публикует команды устройствам" "MQTT"
    mqtt -> api "Доставляет подтверждения" "MQTT"
    mqtt -> devices "Доставляет команды" "MQTT"
    devices -> mqtt "Публикует показания и подтверждения" "MQTT"
    api -> eventBus "Публикует события" "AMQP"
    eventBus -> journalWorker "Доставляет события журнала" "AMQP"
    journalWorker -> db "Пишет журнал" "JDBC"
    eventBus -> notification "Доставляет события для уведомлений" "AMQP"
    notification -> tg "Отправляет уведомления" "HTTPS"
    api -> police "Передаёт аварийный сигнал" "HTTPS"

    tg -> commandController "Передаёт команду" "HTTPS"
    friday -> commandController "Передаёт распознанную команду" "HTTPS"
    tech -> commandController "Запрашивает журнал и диагностику" "HTTPS"
    commandController -> policyService "Проверяет права" "in-process"
    commandController -> deviceService "Отправляет команду" "in-process"
    commandController -> journalService "Фиксирует событие" "in-process"
    commandController -> notificationService "Формирует уведомление" "in-process"
    policyService -> db "Читает роли и права" "JDBC"
    deviceService -> mqtt "Публикует команду" "MQTT"
    journalService -> eventBus "Публикует событие" "AMQP"
    notificationService -> eventBus "Публикует запрос на уведомление" "AMQP"
  }

  views {
    systemContext smartHome "Context" {
      include *
      autolayout lr
    }

    container smartHome "Containers" {
      include *
      autolayout lr
    }

    component api "Components" {
      include *
      autolayout lr
    }

    dynamic smartHome "DeviceControl" "Управление устройством" {
      resident -> tg "1. Команда «включить свет»"
      tg -> api "2. Передаёт команду"
      api -> db "3. Проверяет права"
      api -> mqtt "4. Публикует команду"
      mqtt -> devices "5. Доставляет команду"
      devices -> mqtt "6. Публикует подтверждение"
      mqtt -> api "7. Доставляет подтверждение"
      api -> eventBus "8. Публикует CommandCompleted"
      eventBus -> journalWorker "9. Передаёт событие журнала"
      journalWorker -> db "10. Записывает событие"
      eventBus -> notification "11. Передаёт запрос на уведомление"
      notification -> tg "12. Отправляет статус"
      tg -> resident "13. Показывает результат"
    }
  }
}
