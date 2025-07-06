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

     /// 1 点保存（成功/失敗を返す）
     func save(trackPoint: CLLocation) -> Bool {
         let ctx = container.viewContext
         let tp = TrackPoint(context: ctx)
         tp.id        = .init()
         tp.timestamp = trackPoint.timestamp
         tp.lat       = trackPoint.coordinate.latitude
         tp.lon       = trackPoint.coordinate.longitude
         tp.hAcc      = trackPoint.horizontalAccuracy
         tp.speed     = trackPoint.speed

         do {
             try ctx.save()
             return true
         } catch {
             print("CoreData save error", error)
             return false
         }
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
     
     /// 全データ削除
     func deleteAll() {
         let context = container.viewContext
         let request = TrackPoint.fetchRequest()
         
         do {
             let points = try context.fetch(request)
             for point in points {
                 context.delete(point)
             }
             try context.save()
         } catch {
             print("全データ削除エラー:", error)
         }
     }
     
     /// 総データ数取得
     func getTotalCount() -> Int {
         let context = container.viewContext
         let request = TrackPoint.fetchRequest()
         
         do {
             return try context.count(for: request)
         } catch {
             print("データ数取得エラー:", error)
             return 0
         }
     }
     
     /// 最古データ取得
     func getOldestRecord() -> TrackPoint? {
         let context = container.viewContext
         let request = TrackPoint.fetchRequest()
         request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
         request.fetchLimit = 1
         
         do {
             return try context.fetch(request).first
         } catch {
             print("最古データ取得エラー:", error)
             return nil
         }
     }
     
     /// 最新データ取得
     func getNewestRecord() -> TrackPoint? {
         let context = container.viewContext
         let request = TrackPoint.fetchRequest()
         request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
         request.fetchLimit = 1
         
         do {
             return try context.fetch(request).first
         } catch {
             print("最新データ取得エラー:", error)
             return nil
         }
     }
 }
