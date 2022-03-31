//
//  DetailCell.swift
//  Time Dots
//
//  Created by Cristian Lăpușan on Mon  29.03.2021.
//  

import UIKit
import CoreData

extension BottomCell {
    struct PairCellContent:Hashable {
        let id:Int
        let startD:String
        let startT:String
        let pauseD:String
        let pauseT:String
        let duration:String
        let sticky:String
        let isStickyDisplayed:Bool
    }
    
    typealias Item = NSCollectionLayoutItem
    typealias Group = NSCollectionLayoutGroup
    typealias Layout = UICollectionViewCompositionalLayout
    typealias Size = NSCollectionLayoutSize
}

class BottomCell: UICollectionViewCell {
    deinit {
//           print("BottomCell deinit")
       }
    
    // MARK: - Diffable Data Source
    enum Section {
        case main
        case subtitle
    }
    private var dataSource:UICollectionViewDiffableDataSource<Section, Pair>!
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Pair>(collectionView: collectionView) {
            [weak self] collectionView, indexPath, pair -> PairCell? in
            guard let self = self else { return nil }
            
            let pairCell =
                collectionView.dequeueReusableCell(withReuseIdentifier: "pairCell", for: indexPath) as! PairCell
            //handles sticky notes
            if pairCell.delegate == nil { pairCell.delegate = self }
            
            //refactor this
            let dateStyle = DateFormatter.tbDateStyle
            let timeStyle = DateFormatter.tbTimeStyle
            
            var pauseT = String.empty
            var pauseD = String.empty
            if let pauseDate = pair.stop {
                pauseT = timeStyle.string(from: pauseDate)
                pauseD = dateStyle.string(from: pauseDate)
            }
            var duration = String.empty
            if pair.duration != 0 {
                duration = TimeInterval(pair.duration).timeAsString()
            }
            
            pairCell.pairCellContent = PairCellContent(id: UUID().hashValue,
                                                       startD: dateStyle.string(from: pair.start!),
                                                       startT: timeStyle.string(from: pair.start!),
                                                       pauseD: pauseD,
                                                       pauseT: pauseT,
                                                       duration: duration,
                                                       sticky: pair.sticky,
                                                       isStickyDisplayed: pair.isStickyVisible)
            
            let condition = self.traitCollection.userInterfaceStyle == .dark && self.color == .charcoal
            pairCell.colorAccolade.set(strokeColor: condition ? .white : self.color.withAlphaComponent(1.0))
            pairCell.pairNumberLabel.text = String(self.pairs.count - indexPath.row)
            
            //note symbol
            let showNoteSymbol = (!pair.isStickyVisible && !pair.sticky.isEmpty) ? true : false
            pairCell.noteSymbol.alpha = showNoteSymbol ? 1 : 0
            
            return pairCell
        }
    }
    
    private func header(_ indexPath:IndexPath) -> TimerSubtitleHeader {
        let header =
            collectionView.dequeueReusableSupplementaryView(ofKind: TimerSubtitleHeader.reuseID,
                                                      withReuseIdentifier: TimerSubtitleHeader.reuseID,
                                                      for: indexPath) as? TimerSubtitleHeader
        return header!
    }
    
    private func setSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Pair>()
        if snapshot.sectionIdentifiers.isEmpty {
            snapshot.appendSections([.main])
        }
        snapshot.appendItems(pairs, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: -
    static let reuseID = "bottomCell"
    private let pairCellHeight = CGFloat(125)
    private let fineTunningPercent = CGFloat(0.8)
    
    //avoid pairCell to be covered by keyboard
    private var cellBoundsInCVCoordinateSpace:CGRect?
        
    // MARK: -
    //data coming from DetailVC
    var color:UIColor!
    var pairs = [Pair]() {didSet{
        pairs.reverse()
        setSnapshot()
    }}
    
    private var layoutSetAlready = false
    
    ///embeded collection view presenting the pairs
    @IBOutlet weak var collectionView: UICollectionView! {didSet{
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        
        //register cell
        let pairCellNib = UINib(nibName: "PairCell", bundle: nil)
        collectionView.register(pairCellNib, forCellWithReuseIdentifier: "pairCell")
        
        setupKillKeyboard()
        
        registerFor_KeyboardFrame_Updates()
        
        registerFor_TexfieldDidBeginEditing()
        
        collectionView.collectionViewLayout = compositionalLayout()
        
        setupDataSource()
    }}
    
    private func compositionalLayout() -> UICollectionViewCompositionalLayout {
        //1.item
        let itemSize = Size(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(pairCellHeight))
        let item = Item(layoutSize: itemSize)
        
        //2.group
        let height:CGFloat = (pairCellHeight * fineTunningPercent) * CGFloat(10)
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(height))
        let group = Group.vertical(layoutSize: size, subitems: [item])
        
        //3.section
        let section = NSCollectionLayoutSection(group: group)
        
        //4. header subtitle (timers only)
//        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
//        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: TimerSubtitleHeader.reuseID, alignment: .top)

//        section.boundarySupplementaryItems = [header]
        
        //4.layout
        return Layout(section: section)
    }
}

extension BottomCell: UICollectionViewDelegate {
    //hide/show sticky note
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let pairCell = collectionView.cellForItem(at: indexPath) as? PairCell
        else { fatalError() }
        let pair = pairs[indexPath.row]
        
        if pair.sticky.isEmpty { showStickiesView(for: pair, and: pairCell) }
        else {
            pair.isStickyVisible = !pair.isStickyVisible
            CoreDataStack.shared.saveContext()
        }
        
        //more UI
        pairCell.stickyNoteLook(pair.sticky, pair.isStickyVisible)
        pairCell.reactToTap(1, .light)
    }
    
    private func showStickiesView(for pair:Pair, and pairCell:PairCell) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let stickiesVC = storyboard.instantiateViewController(withIdentifier: "StickiesVC") as? StickiesVC else { return }
        guard let detailVC = viewController() as? DetailVC else { return }
        
        NotificationCenter.default.post(name: Post.animatePairCell, object: pairCell)
                
        //send data payload
        stickiesVC.pair = pair
        stickiesVC.reloadStickies = collectionView.reloadData
        
        detailVC.present(stickiesVC, animated: false)
    }
}

extension BottomCell: PairCellDelegate {
    func userWantsToDeleteSticky(for pairCell:PairCell) {
        //delete sticky note
        guard
            let indexPath = collectionView.indexPath(for: pairCell),
            let pair = dataSource.itemIdentifier(for: indexPath)
        else { fatalError() }
        pair.sticky = ""
        CoreDataStack.shared.saveContext()
    }
    
    //save sticky added by user
    func userAddedSticky(for pairCell:PairCell, sticky: String) {
        guard
            let indexPath = collectionView.indexPath(for: pairCell)
        else { return }
        
        let pair = pairs[indexPath.row]
        let oldSticky = pair.sticky
        
        var newSticky = sticky
        
        //clean up sticky. ex: " Gym " becomes "Gym"
        newSticky.trimWhiteSpaceAtTheBeginning()
        newSticky.trimWhiteSpaceAtTheEnd()
        
        if newSticky != oldSticky {//no reason to save to CoreData if stickies are the same
            pair.sticky = newSticky
            CoreDataStack.shared.saveContext()
            CalendarEventsManager.shared.updateEvent(.notes(pair.session!))
        }
    }
    
    func userWantsToEditSticky(for pairCell:PairCell) {
        guard
        let indexPath = collectionView.indexPath(for: pairCell),
        let pair = dataSource.itemIdentifier(for: indexPath)
        else { fatalError() }
        
        showStickiesView(for: pair, and: pairCell)
    }
}

// MARK: - Avoid keyboard covering the cell
extension BottomCell {
    private func registerFor_TexfieldDidBeginEditing() {
        let nc = NotificationCenter.default
        let post = Post.textFieldDidBeginEditing
        nc.addObserver(forName: post, object: nil, queue: nil) {
            [weak self] notification in
            guard
                let self = self,
                let pairCell = ((notification.object as? StickyNote)?.superview?.superview as? PairCell)
            else { return }
            
            self.cellBoundsInCVCoordinateSpace = pairCell.convert(pairCell.bounds, to: nil) /* ⚠️ bounds not frame! */
            
            if
                let indexPath = self.collectionView.indexPath(for: pairCell),
                let pair = self.dataSource.itemIdentifier(for: indexPath) {
                                
                self.showStickiesView(for: pair, and: pairCell)
            }
        }
    }
    
    private func registerFor_KeyboardFrame_Updates() {
        let nc = NotificationCenter.default
        let willChangeFrame = UIResponder.keyboardWillChangeFrameNotification
        nc.addObserver(self, selector: #selector(adjustViewForKeyboard), name: willChangeFrame, object: nil)
    }
    
    @objc private func adjustViewForKeyboard(notification:Notification) {
        let key = UIResponder.keyboardFrameEndUserInfoKey
        guard let keyboardFrame = (notification.userInfo![key] as? CGRect) else {return}
        
        if keyboardFrame.origin.y < UIScreen.main.bounds.height {
            guard let cellBounds = cellBoundsInCVCoordinateSpace else { return }
            
            let obscureAmount = (cellBounds.origin.y + cellBounds.size.height) - keyboardFrame.origin.y
            if obscureAmount > 0 {
                collectionView.transform = CGAffineTransform(translationX: 0, y: -obscureAmount)
            }
        }
        else { collectionView.transform = .identity }
    }
}
