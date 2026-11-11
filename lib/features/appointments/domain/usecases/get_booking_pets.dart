import '../entities/appointment.dart';
import '../repositories/appointments_repository.dart';

class GetBookingPets {
  final AppointmentsRepository repository;
  GetBookingPets(this.repository);
  Future<List<BookingPet>> call() => repository.getMyPets();
}
