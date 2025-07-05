import CoreData
import CoreLocation

 // ⚠️ ほぼシングルトンで良い
 @MainActor
 final class PersistenceService: ObservableObject {
     static let shared = PersistenceService()

     // MARK: - Core Data stack
     let container: NSPersistentContainer

     private init(inMemory: Bool = false) {
         container = NSPersistentContainer(name: "GPSLogger") // .xcdatamodeld 名
         if inMemory {
             container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
         }
         container.loadPersistentStores { _, error in
             if let error { fatalError("CoreData load error: \(error)") }
         }
         container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
         container.viewContext.automaticallyMergesChangesFromParent = true
     }

     // MARK: - CRUD

     /// 1 点保存
     func save(trackPoint: CLLocation) {
         let ctx = container.viewContext
         let tp = TrackPoint(context: ctx)
         tp.id        = .init()
         tp.timestamp = trackPoint.timestamp
         tp.lat       = trackPoint.coordinate.latitude
         tp.lon       = trackPoint.coordinate.longitude
         tp.hAcc      = trackPoint.horizontalAccuracy
         tp.speed     = trackPoint.speed

         do    { try ctx.save() }
         catch { print("CoreData save error", error) }
     }

     /// 直近 limit 件を降順で取得
     func fetch(limit: Int = 100) -> [TrackPoint] {
         let req = TrackPoint.fetchRequest()
         req.sortDescriptors = [NSSortDescriptor(key: #keyPath(TrackPoint.timestamp), ascending: false)]
         req.fetchLimit = limit
         do    { return try container.viewContext.fetch(req) }
         catch {
             print("CoreData fetch error", error)
             return []
         }
     }

     /// 古いデータを削除（例:30 日より前）
     func purge(olderThan days: Int = 30) {
         let date = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
         let req  = TrackPoint.fetchRequest()
         req.predicate = NSPredicate(format: "timestamp < %@", date as NSDate)

         let delete = NSBatchDeleteRequest(fetchRequest: req as! NSFetchRequest<NSFetchRequestResult>)
         do    { try container.persistentStoreCoordinator.execute(delete, with: container.viewContext) }
         catch { print("purge error", error) }
     }
 }
