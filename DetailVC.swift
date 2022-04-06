//
//  DetailVC0.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 01.06.2021.
//

import UIKit
import CoreData

extension DetailVC {
    typealias Group = NSCollectionLayoutGroup
    typealias Layout = UICollectionViewCompositionalLayout
    typealias Configuration = UICollectionViewCompositionalLayoutConfiguration
    typealias Item = NSCollectionLayoutItem
    typealias LayoutSize = NSCollectionLayoutSize
    typealias Suppliment = NSCollectionLayoutBoundarySupplementaryItem
    typealias CV = UICollectionView
    typealias Cell = UICollectionViewCell
    typealias ReusableView = UICollectionReusableView
    typealias MenuConfiguration = UIContextMenuConfiguration
    typealias MenuInteraction = UIContextMenuInteraction
    typealias Action = UIAction
    typealias Menu = UIMenu
    typealias Bubble = CT
    typealias Section = NSCollectionLayoutSection
}

class DetailVC: UIViewController {
    deinit {
//        print("DetailVC deinit")
    }
    
    // MARK: - Layout
    let circleDiameter = CGFloat(110)
    let circleSectionInsetTop = CGFloat(2)
    
    ///historyEmptyStack will be placed vertically in the middle of the screen but offset by 120/2 = 60
    private let headerHeight = CGFloat(120)
    
    private func circleLayout() -> Layout {
        Layout {[weak self] _,_ in
            self?.circleSection()
        }
    }
    private func masterLayout() -> Layout {
        Layout {[weak self] _,_ in
            self?.masterSection()
        }
    }
    
    private func circleSection() -> NSCollectionLayoutSection {
        //item
        let sessionCircleSize = LayoutSize(widthDimension: .fractionalHeight(1.35), heightDimension: .fractionalHeight(1.0))
        let circle = Item(layoutSize: sessionCircleSize)
        circle.contentInsets.leading = 0
        
        //group
        let groupSize = LayoutSize(widthDimension: .fractionalWidth(10),
                                   heightDimension: .absolute(circleDiameter))
        let circleGroup = Group.horizontal(layoutSize: groupSize, subitems: [circle])
        circleGroup.interItemSpacing = .fixed(2)
        circleGroup.contentInsets.leading = 10
        
        //section
        let circleSection = NSCollectionLayoutSection(group: circleGroup)
        circleSection.orthogonalScrollingBehavior = .continuous
        circleSection.contentInsets.top = circleSectionInsetTop
        
        //section header
        let headerSize = LayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .estimated(headerHeight))
        let header =
            Suppliment(layoutSize: headerSize, elementKind: Header.reuseID, alignment: .top)
        circleSection.boundarySupplementaryItems = [ header ]
        
        return circleSection
    }
    
    private func masterSection() -> NSCollectionLayoutSection {
        //item
        let itemSize = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1.0) , heightDimension:.fractionalHeight(1.0))
        let item = Item(layoutSize: itemSize)
        item.contentInsets = .init(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        //group
        let masterGroupSize = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1.0) ,
                                                     heightDimension:.fractionalHeight(1))
        let masterGroup = NSCollectionLayoutGroup.horizontal(layoutSize: masterGroupSize, subitems: [item])
        masterGroup.contentInsets.top = 4
        
        //section
        let masterSection = NSCollectionLayoutSection(group: masterGroup)
        masterSection.orthogonalScrollingBehavior = .groupPagingCentered
        masterSection.contentInsets.top = 2.0
        
        //section: replaces scrollView delegate
        masterSection.visibleItemsInvalidationHandler = {
            [weak self] (visibleItems, currentScrollOffset, environment) in
            
            let screenWidth = environment.container.contentSize.width
            if let itemNumber = self?.scrollStopped(currentScrollOffset.x, screenWidth) {
                if itemNumber == 0 { self?.makeSureCirclesBlinkInThePaircell() }
                let indexPath = IndexPath(row: itemNumber, section: 0)
                self?.scrollToCircleAndSelect(at: indexPath)
            }
        }
        
        return masterSection
    }
    
    // MARK: - Data coming from CTTVC and derived data
    var bubbleID:UUID! {didSet{ bubble = bubble(with: bubbleID) }}
    
    private weak var bubble:Bubble! {didSet{
        //set other properties
        headerTitle = bubble.kindDescription
        referenceClock = Int(bubble.referenceClock)
        bubbleIsRunning = bubble.state == .running
    }}
    
    private lazy var tintColor:UIColor = {
      (color == .charcoal) ? UIColor.charcoalTint : color ?? .black
    }()
    
    private lazy var color:UIColor? = {
        let searchedColor = bubble.color ?? "gray"
        return TricolorProvider.tricolors(forName: searchedColor).first?.intense
    }()
    private var headerTitle:String!
    private var referenceClock:Int!
    private var bubbleIsRunning:Bool!
    
    private var theOneAndOnlySelectedCircle:TopCell? {didSet{
        theOneAndOnlySelectedCircle?.stayFill = true
        self.select(true, theOneAndOnlySelectedCircle)
    }}
    
    // MARK: - outlets and actions
    @IBOutlet weak var historyEmptyImage: UIImageView! {didSet{
        let image = historyEmptyImage.image?.withTintColor(tintColor)
        historyEmptyImage.image = image
    }}
    
    @IBOutlet weak var historyEmptyStack: UIStackView! {didSet{
        if bubble.bubbleSessions.isEmpty {
            historyEmptyStack.isHidden = false
        }
    }}
    
    @IBOutlet weak var hintTitleLabel: UILabel! {didSet{
        hintTitleLabel.font = UIFont.hintTitle
    }}
    
    @IBOutlet weak var hintBodyLabel: UILabel! {didSet{
        hintBodyLabel.font = UIFont.hintBody
        hintBodyLabel.text = "Swipe right on\nTitle \"\(bubble.kindDescription)\"\nto dismiss"
    }}
    
    @IBOutlet weak var topCollectionView: UICollectionView! {didSet{
        topCollectionView.alwaysBounceVertical = false
    }}
    @IBOutlet weak var bottomCollectionView: UICollectionView!
    
    @IBOutlet weak var background: UIView!
    
    @IBAction func dismissSelf(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set layouts
        topCollectionView.collectionViewLayout = circleLayout()
        bottomCollectionView.collectionViewLayout = masterLayout()
        
        //set data sources and delegates
        topCollectionView.dataSource = topCellDataSource
        topCollectionView.delegate = self
        setupTopCellDataSource()
        
        bottomCollectionView.dataSource = bottomCellDataSource
        bottomCollectionView.delegate = self
        setupBottomCellDataSource()
        
        //register header and cells
        let headerNib = UINib(nibName: "Header", bundle: nil)
        topCollectionView.register(headerNib,
                          forSupplementaryViewOfKind: Header.reuseID,
                          withReuseIdentifier: Header.reuseID)
        
        let topCellNib = UINib(nibName: "TopCell", bundle: nil)
        topCollectionView.register(topCellNib, forCellWithReuseIdentifier: TopCell.reuseID)
        
        let bottomCellNib = UINib(nibName: "BottomCell", bundle: nil)
        bottomCollectionView.register(bottomCellNib, forCellWithReuseIdentifier: BottomCell.reuseID)
        
        //custom view controller transition delegate
        transitioningDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCircleSnapshot()
        setMasterSnapshot()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        topCollectionView.clipsToBounds = false
    }
    
    // MARK: - DiffDataSources
    // MARK: TopCell
    private var topCellDataSource:UICollectionViewDiffableDataSource<TopSection, Session>!
    
    enum TopSection { case main }
    
    private func setupTopCellDataSource() {
        topCellDataSource = UICollectionViewDiffableDataSource<TopSection, Session>(collectionView: topCollectionView) {
            [weak self] (_, indexPath, session) -> TopCell? in
            self?.topCell(at: indexPath, session)
        }
        
        topCellDataSource.supplementaryViewProvider = {
            [weak self] _, _, indexPath -> ReusableView? in
            self?.header(indexPath)
        }
    }
    
    private func setCircleSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<TopSection, Session>()
        if snapshot.sectionIdentifiers.isEmpty {
            snapshot.appendSections([.main])
        }
        snapshot.appendItems(bubble.bubbleSessions.reversed(), toSection: .main)
        topCellDataSource.apply(snapshot)
    }
    
    // MARK: BottomCell
    private var bottomCellDataSource:UICollectionViewDiffableDataSource<BottomSection, Session>!
    
    enum BottomSection { case main }
    
    private func setupBottomCellDataSource() {
        bottomCellDataSource = UICollectionViewDiffableDataSource<BottomSection, Session>(collectionView: bottomCollectionView) {
            [weak self] (cv, indexPath, session) -> BottomCell? in
            guard let self = self else {return nil}
            
            let bottomCell = cv.dequeueReusableCell(withReuseIdentifier: BottomCell.reuseID, for: indexPath) as? BottomCell
            bottomCell?.color = self.color
            bottomCell?.pairs = session._pairs
            return bottomCell
        }
    }
    
    private func setMasterSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<BottomSection, Session>()
        if snapshot.sectionIdentifiers.isEmpty {
            snapshot.appendSections([.main])
        }
        snapshot.appendItems(bubble.bubbleSessions.reversed(), toSection: .main)
        bottomCellDataSource.apply(snapshot)
    }
}

// MARK: - Helpers
extension DetailVC {
    private func bubble(with id:UUID) -> Bubble {
        let request:NSFetchRequest<CT> = CT.fetchRequest()
        if let bubbles = try? AppDelegate.context.fetch(request) {
            if let bubble = bubbles.filter ({ $0.id == id }).first { return bubble }
            else { fatalError() }
        } else { fatalError() }
    }
    
    //simplify cells and headers
    private func header(_ indexPath:IndexPath) -> Header {
        let header =
            topCollectionView.dequeueReusableSupplementaryView(ofKind: Header.reuseID,
                                                      withReuseIdentifier: Header.reuseID,
                                                      for: indexPath) as? Header
        
        header?.titleSymbol.titleLabel.text = headerTitle
        header?.titleSymbol.titleLabel.textColor = color
        header?.titleSymbol.symbol.tintColor = color
        
        if color == .charcoal && traitCollection.userInterfaceStyle == .dark {
            header?.titleSymbol.titleLabel.textColor = .white
            header?.titleSymbol.symbol.tintColor = .white
        }
        
        if referenceClock == 0 { header?.titleSymbol.symbol.image = UIImage(systemName: "stopwatch") }
        
        if referenceClock != 0 {/* timers */
            let time = referenceClock.time()
            header?.hoursLabel.text = String(time.hr)
            header?.minutesLabel.text = String(time.min)
            header?.secondsLabel.text = String(time.sec)
            
            if time.hr == 0 { header?.hoursStack.isHidden = true }
            if time.min == 0 { header?.minutesStack.isHidden = true }
            if time.sec == 0 { header?.secondsStack.isHidden = true }
            
        }
        else { header?.durationStringStack.isHidden = true }
        
        setupForDismiss(header)
        
        return header!
    }
    
    //helper
    private func dayLabelText(_ pairs:[Pair]) -> String {
        var text = ""
        
        let start = pairs.first!.start!
        
        text = start.dayOnly
        
        if let stop = pairs.last?.stop {
            if stop.dayOnly != start.dayOnly { text.append(" - \(stop.dayOnly)") }
        }
        
        return text
    }
    
    private func topCell(at indexPath:IndexPath, _ session:Session) -> TopCell {
        let topCell = topCollectionView.dequeueReusableCell(withReuseIdentifier: TopCell.reuseID, for: indexPath) as! TopCell
       
        //1.reset content that needs to be reseted
                                
        //2.configure topCell
        topCell.sessionNumberLabel.text = String(bubble.bubbleSessions.count - indexPath.row)
        
        topCell.color = color
        topCell.colorString = bubble.color
                
        topCell.setDuration(session.totalDuration())
        topCell.dayLabel.text = dayLabelText(session._pairs)
        
        //blinking dots
        if session.isLastPairClosed {//not running
            topCell.bubbleActiveShouldBlink = false
            topCell.durationStack.alpha = 1
        } else {//running
            if self.bubble.bubbleSessions.last == session {
                topCell.bubbleActiveShouldBlink = true
                topCell.durationStack.alpha = 0
            }
        }
        
        return topCell
    }
    
    private func bottomCell(at indexPath:IndexPath, _ session:Session) -> BottomCell {
        let id = BottomCell.reuseID
        let bottomCell = topCollectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! BottomCell
        bottomCell.color = color
        return bottomCell
    }
    
    private func scrollStopped(_ offsetX:CGFloat, _ screenWidth:CGFloat) -> Int? {
        let isDividingExactly = CGFloat(Int(offsetX/screenWidth)) == offsetX/screenWidth
        return isDividingExactly ? Int(offsetX/screenWidth) : nil
    }
    
    private func showCorrespondingItem(forSource indexPath:IndexPath) {
        bottomCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    private func select(_ isSelected:Bool, _ cell:TopCell?) {
        
        //1. deselect all cells first!
        topCollectionView.visibleCells.forEach { ($0 as? TopCell)?.isFill = false }
        
        //2. select or deselect the circle
        guard let cell = cell else { return }
        cell.isFill = isSelected ? true : false
    }
    
    ///when user scrolls bottomcells, the topCell scrolls too
    private func scrollToCircleAndSelect(at indexPath:IndexPath) {
        //scroll to circle
        topCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        //select circle with 0.2 delay. 0.1 too little
        delayExecution(.now() + 0.2) {[weak self] in
            let topCell = self?.topCollectionView.cellForItem(at: indexPath) as? TopCell
            self?.theOneAndOnlySelectedCircle = topCell
        }
    }
    
    ///if the circles must blink, if lastPair not closed, they should blink by force hahaha
    private func makeSureCirclesBlinkInThePaircell() {
        if let lastPairClosed = bubble.currentSession?.isLastPairClosed, !lastPairClosed {
            let indexPath = IndexPath(row: 0, section: 0)
            delayExecution(.now() + 0.3) {[weak self] in
                ((self?.bottomCollectionView.visibleCells.first as? BottomCell)?.collectionView.cellForItem(at: indexPath) as? PairCell)?.blinkingCircles.blink(true, hide: false)
            }
        }
    }
}

extension DetailVC {
    ///dismiss DetailVC in two ways 1.right swipe on header or 2.tap header
    private func setupForDismiss(_ header:Header?) {
        guard let header = header else { return }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panToDismiss(_:)))
        
        header.addGestureRecognizer(tap)
        header.addGestureRecognizer(pan)
        
        header.colorBackground.set(cornerRadius: 20, fillColor: header.titleSymbol.titleLabel.textColor)
    }
    
    @objc func tapToDismiss(_ sender:UITapGestureRecognizer) {
        guard let header = sender.view as? Header
        else { fatalError("no header here stupid!") }
        
        if sender.state == .ended {
            UIView.animate(withDuration: 0.1) {
                header.whiteBackground.transform = CGAffineTransform(translationX: 60, y: 0)
            }
            UserFeedback.triggerSingleHaptic(.soft)
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func panToDismiss(_ sender:UIPanGestureRecognizer) {
        guard let header = sender.view as? Header else {return}
        
        switch sender.state {
        
        case .changed:
            let translationX = sender.translation(in: header).x
            guard translationX > 0 else { return }
            
            header.whiteBackground.transform = CGAffineTransform(translationX: translationX, y: 0)
            if translationX >= 60 {
                UserFeedback.triggerSingleHaptic(.soft)
                topCollectionView.clipsToBounds = true
                presentingViewController?.dismiss(animated: true, completion: nil)
            }
            
        case .cancelled:
            UIView.animate(withDuration: 0.1) { header.whiteBackground.transform = .identity }
            
        case .ended:
            UIView.animate(withDuration: 0.1) { header.whiteBackground.transform = .identity }
            
        default: break
        }
    }
}

extension DetailVC:UICollectionViewDelegate {
    //called only on the topCell
    func collectionView(_ collectionView: CV, didSelectItemAt indexPath: IndexPath) {
        showCorrespondingItem(forSource:indexPath) //show the master cell
        
        let cell = collectionView.cellForItem(at: indexPath) as? TopCell
        theOneAndOnlySelectedCircle = cell
        cell?.reactToTap()
    }
}

extension DetailVC: UIContextMenuInteractionDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        
    }
    
    func contextMenuInteraction(_ interaction: MenuInteraction, configurationForMenuAtLocation location: CGPoint) -> MenuConfiguration? {
        return nil
    }
    
    func collectionView(_ collectionView: CV, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> MenuConfiguration? {
        //cant't delete newest session if timedot is running
        if indexPath.row == 0 && bubbleIsRunning { return nil }
                
        guard indexPath.section == 0 else { return nil }
        let count = bubble.bubbleSessions.count - 1
        let session = bubble.bubbleSessions[count - indexPath.row]
        
        let sessionTotalDurationTitle = "\(session.totalDuration().timeAsString())"
        let clock = UIImage(systemName: "hourglass")
        let totalDuration = Action(title: sessionTotalDurationTitle, image: clock) { _ in }
        
        //delete action
        let title = bubble.isCalendarEnabled ?
            "Delete Session \(count - indexPath.row + 1)\n& its Calendar Event" :
            "Delete Session \(count - indexPath.row + 1)"
        
        let deleteAction = Action(title: title, attributes: .destructive) {
            [weak self] action in
            guard let self = self else { return }
            /* ⚠️ why the fuck is it reversed here too */
            self.delete(session)
            if self.bubble.bubbleSessions.isEmpty {
                self.historyEmptyStack.isHidden = false
            }
            self.updateSnapshots(for: session)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        
        return MenuConfiguration(identifier: nil, previewProvider: nil) {
            suggestedActions -> Menu? in
            //menu
            let menuTitle = "Session \(count + 1 - indexPath.row)"
            let menu = Menu(title:menuTitle, children: [totalDuration, deleteAction])
            return menu
        }
    }
    
    ///delete a session for the corresponding timedot
    private func delete(_ session:Session?) {
        guard let session = session else { return }
        let willCurrentSessionBeDeleted = bubble.currentSession === session
        if willCurrentSessionBeDeleted { bubble.reconfigure(for: .currentSession) }
        
        //⚠️ order matters. first delete event, since event id is the same as session.id. if session deleted first, calendar event has id set to nil. careful!
        CalManager.shared.deleteEvent(with: session.eventID)
        AppDelegate.context.delete(session) //if session deleted its pairs will be deleted as well
        CoreDataStack.shared.saveContext()
    }
    
    private func updateSnapshots(for session:Session) {
        //circle
        var circleSnapshot = topCellDataSource.snapshot()
        circleSnapshot.deleteItems([session])
        self.topCellDataSource.apply(circleSnapshot, animatingDifferences: false)
        
        //master
        var masterSnapshot = bottomCellDataSource.snapshot()
        masterSnapshot.deleteItems([session])
        bottomCellDataSource.apply(masterSnapshot, animatingDifferences: true)
    }
}

// MARK: - Dark Mode
extension DetailVC {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            if bubble.bubbleSessions.isEmpty {
                historyEmptyImage.isHidden = false
            }
        }
    }
}

// MARK: - custom view controller transition
extension DetailVC:UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        PresentAnimationController(slideDirection: .rightToLeft)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DismissAnimationController(slideDirection: .leftToRight)
    }
}

extension UIViewController {
    var isDarkModeOn:Bool {
        traitCollection.userInterfaceStyle == .dark
    }
}
