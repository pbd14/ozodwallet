import 'languages.dart';

class LanguageRu extends Languages {
  @override
  String get welcomeToOzod => "ДОБРО ПОЖАЛОВАТЬ";
  @override
  String get labelSelectLanguage => "Русский";
  @override
  String get loginScreen1head => "Онлайн бронирование";
  @override
  String get loginScreen1text =>
      "Бронируйте онлайн без проблем. Больше нет нужды связываться с администраторами и вести долгую беседу";
  @override
  String get loginScreen2head => "2 минуты";
  @override
  String get loginScreen2text =>
      "Всего лишь 2 минуты чтобы забронировать услугу в любом месте";
  @override
  String get loginScreen3head => "Комфорт";
  @override
  String get loginScreen3text =>
      "Мы предлагаем удобное расписание и систему которая регулирует и организовывает ваши броны";
  @override
  String get getStarted => "Начнем";
  @override
  String get loginScreenYourPhone => "Телефон";
  @override
  String get loginScreen6Digits => "Минимум 6 символов";
  @override
  String get loginScreenEnterCode => "Введите код";
  @override
  String get loginScreenReenterPhone => "Поменять номер телефона";
  @override
  String get loginScreenPolicy =>
      "Продолжая вы принимаете все правила пользования приложением и нашу Политику Конфиденциальности";
  @override
  String get loginScreenCodeIsNotValid => "Время действия кода истекло";

  @override
  String get homeScreenBook => "Брон";
  @override
  String get homeScreenFail => "Ошибка";
  @override
  String get homeScreenFailedToUpdate => "Не удалось обновить";
  @override
  String get homeScreenSaved => "Сохранено";

  @override
  String get mapScreenSearchHere => "Искать близлежащие парковки";
  @override
  String get mapScreenLoadingMap => "Загрузка карты...";

  @override
  String get businessScreentext1 =>
      "У вас есть неиспользуемые парковочные места? Монетизируйте их.";
  @override
  String get businessScreentext2 =>
      "Сдавайте парковочное место в аренду и зарабатывайте вместе с Easark. Это просто, удобно и выгодно.";

  @override
  String get serviceScreenNoInternet => "Нет соединения с Интернетом";
  @override
  String get serviceScreenClosed => "Закрыто";
  @override
  String get serviceScreenDate => "Дата";
  @override
  String get serviceScreenFrom => "От";
  @override
  String get serviceScreenTo => "До";
  @override
  String get serviceScreenAlreadyBooked => "Уже забронированно";
  @override
  String get serviceScreenIncorrectDate => "Выбрана неверная дата";
  @override
  String get serviceScreenIncorrectTime => "Выбрано неверное время";
  @override
  String get serviceScreenTooEarly => "Слишком рано";
  @override
  String get serviceScreenTooLate => "Слишком поздно";
  @override
  String get serviceScreen2HoursAdvance =>
      "Для этого места необходимо сделать предварительный заказ за 2 часа.";
  @override
  String get serviceScreenPaymentMethod => "Выберите способ оплаты";
  @override
  String get serviceScreenCash => "Наличка";
  @override
  String get serviceScreenCreditCard => "Карта";

  @override
  String get historyScreenSchedule => "Расписание";
  @override
  String get historyScreenHistory => "История";
  @override
  String get historyScreenUnpaid => "Неоплачено";
  @override
  String get historyScreenInProcess => "В процессе";
  @override
  String get historyScreenUpcoming => "Предстоящие";
  @override
  String get historyScreenUnrated => "Без оценки";
  @override
  String get historyScreenVerificationNeeded => "Ожидание согласия владельца";

  @override
  String get oeScreenNotStarted => "Мероприятие еще не началось";
  @override
  String get oeScreenInProcess => "Мероприятие в процессе";
  @override
  String get oeScreenEnded => "Событие закончилось";
  @override
  String get oeScreenMakePayment =>
      "Пожалуйста, произведите оплату и проверьте, принял ли ее владелец";
  @override
  String get oeScreenMakePaymentWith => "Пожалуйста, произведите оплату -";

  @override
  String get oeScreenOverallPrice => "Общая цена";
  @override
  String get oeScreenCancel => "Отменить";
  @override
  String get oeScreenStatus => "Статус";
  @override
  String get oeScreenCanCancel =>
      "Вы можете отменить мероприятие за 2 часа до его начала. Вы можете отменить только 5 бронирований. Вы отменили";
  @override
  String get oeScreenQuestionCancel =>
      "Вы уверены, что хотите отменить бронирование";
  @override
  String get oeScreenReason => "Причина";
  @override
  String get oeScreenMinCharacters => "Минимум символов";
}
