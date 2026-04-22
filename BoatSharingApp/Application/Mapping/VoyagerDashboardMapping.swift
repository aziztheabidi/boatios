import Foundation

enum VoyagerDashboardMapping {

    static func dockLocation(from dto: DockDTO) -> DockLocation {
        DockLocation(
            id: dto.id,
            name: dto.name,
            zone: dto.zone,
            state: dto.state,
            city: dto.city,
            zipCode: dto.zipCode,
            shoreLine: dto.shoreLine,
            address: dto.address,
            latitude: dto.latitude,
            longitude: dto.longitude,
            dockTypeId: dto.dockTypeId,
            dockType: dto.dockType,
            userId: dto.userId,
            changedOn: dto.changedOn,
            changedBy: dto.changedBy
        )
    }

    static func activeDocks(from response: ActiveDocksResponseDTO) -> ActiveDocks {
        ActiveDocks(
            all: response.obj.all.map { dockLocation(from: $0) },
            business: response.obj.business.map { dockLocation(from: $0) }
        )
    }

    static func voyageSession(from dto: VoyagerVoyageDTO) -> VoyageSession {
        VoyageSession(
            id: dto.id,
            captainUserId: dto.captainUserId,
            captainName: dto.captainName,
            pickupDock: dto.pickupDock,
            pickupDockLatitude: dto.pickupDockLatitude,
            pickupDockLongitude: dto.pickupDockLongitude,
            dropOffDock: dto.dropOffDock,
            dropOffDockLatitude: dto.dropOffDockLatitude,
            dropOffDockLongitude: dto.dropOffDockLongitude,
            boatName: dto.boatName,
            boatModel: dto.boatModel,
            otp: dto.otp,
            amountToPay: dto.amountToPay,
            rating: dto.rating,
            status: dto.status,
            voyagerUserId: dto.voyagerUserId,
            voyagerName: dto.voyagerName,
            voyagerPhoneNumber: dto.voyagerPhoneNumber,
            numberOfVoyagers: dto.noOfVoyagers ?? 1,
            duration: dto.duration ?? "",
            waterStay: dto.waterStay ?? "",
            bookingDateTime: dto.bookingDateTime ?? ""
        )
    }
}
