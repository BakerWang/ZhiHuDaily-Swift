//
//  ViewController.swift
//  ZhiHuDaily-Swift
//
//  Created by SUN on 15/5/26.
//  Copyright (c) 2015年 SUN. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UIViewControllerPreviewingDelegate,RefreshControlDelegate,MainTitleViewDelegate,SlideScrollViewDelegate {
    
    private let BACKGROUND_COLOR = UIColor(red: 0.098, green: 0.565, blue: 0.827, alpha: 1)
    
    var leftViewController : UIViewController?
    
    weak var mainTitleViewController : MainTitleViewController?

    var refreshBottomView : RefreshBottomView?
    
    var refreshControl : RefreshControl!
    
    let newsListControl : MainNewsListControl = MainNewsListControl()
    
    // 长按手势标识
    var longPress = UILongPressGestureRecognizer()
    
    //主页面上关联的表格
    @IBOutlet weak var mainTableView: UITableView!
    
    @IBOutlet weak var mainTitleView: UIView!
    
    override func viewDidLoad() {
        
        let nib=UINib(nibName: "NewsListTableViewCell", bundle: nil)
        mainTableView.registerNib(nib, forCellReuseIdentifier: "newsListTableViewCell")
        
        refreshControl = RefreshControl(scrollView: mainTableView, delegate: self)
        refreshControl.topEnabled = true
        refreshControl.bottomEnabled = true
        refreshControl.registeTopView(mainTitleViewController!)
        refreshControl.enableInsetTop = SCROLL_HEIGHT
        refreshControl.enableInsetBottom = 30
        
        let y=max(self.mainTableView.bounds.size.height, self.mainTableView.contentSize.height);
        refreshBottomView = RefreshBottomView(frame: CGRectMake(CGFloat(0),y , self.mainTableView!.bounds.size.width, CGFloat(refreshControl.enableInsetBottom+45)))
        refreshControl.registeBottomView(refreshBottomView!)
        refreshBottomView?.resetLayoutSubViews()
        
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        //检测3D Touch
        check3DTouch()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
    界面切换传值的方法
    
    - parameter segue:
    - parameter sender:
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "mainTitleView" {
            mainTitleViewController = segue.destinationViewController as? MainTitleViewController
            mainTitleViewController?.mainTitleViewDelegate = self
        }else if segue.identifier == "pushSegue" {
            let newsDetailViewController = segue.destinationViewController as? NewsDetailViewController
            
            if  newsDetailViewController?.newsListControl == nil {
                newsDetailViewController?.newsListControl = self.newsListControl
                newsDetailViewController?.mainViewController = self
            }
            
            var index = sender as? NSIndexPath
            
            if index == nil {
                //这里说明不是NSIndexPath 那么就只能是 String了
                let command = sender as! String
                
                if  "newNews" == command {
                    //如果是打开的最新的日报,那么index就应该是 section=0 row = 1
                    index = NSIndexPath(forRow: 1, inSection: 0)
                }else if "xiacheNews" == command {
                    
                    let todayNews = self.newsListControl.todayNews?.news
                    
                    if todayNews != nil {
                        for (i,news) in todayNews!.enumerate() {
                            if news.title.containsString("瞎扯") {
                                //找到瞎扯的文章
                                index = NSIndexPath(forRow: i+1, inSection: 0)
                                break
                            }
                        }
                    }
                    
                    if  index==nil {
                        //如果没有找到 那么就默认打开最新的
                        index = NSIndexPath(forRow: 1, inSection: 0)
                    }
                }
            }
            
            newsDetailViewController?.newsLocation = (index!.section,index!.row)
            
        }
    }
    
    
    //整个View的上下滑动事件的响应
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if  scrollView is UITableView {
            //这部分代码是为了 限制下拉滑动的距离的.当到达scrollHeight后,就不允许再继续往下拉了
            if -Float(scrollView.contentOffset.y)>SCROLL_HEIGHT{
                //表示到顶了,不能再让他滑动了,思路就是让offset一直保持在最大值. 并且 animated 动画要等于false
                scrollView.setContentOffset(CGPointMake(CGFloat(0), CGFloat(-SCROLL_HEIGHT)), animated: false)
                return
            }
        }
    }
    
    func doLeftAction() {
        self.revealController.showViewController(leftViewController!)
    }
    
    //MARK: UITableViewDataSource的实现
    //================UITableViewDataSource的实现================================
    
    //设置tableView的数据行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  section == 0 {
            if  let newsList = newsListControl.todayNews {
                if let news = newsList.news {
                   return news.count+1
                }
            }
            
            return 1
        }else {
            
            if newsListControl.news.count+1 >= section {
                let newsList = newsListControl.news[section-1]
                
                if let news = newsList.news {
                    return news.count
                }
            }
            
            return 0
        }
    }
    
    //返回单元格的高
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        if  indexPath.section==0&&indexPath.row == 0 {
            return CGFloat(IN_WINDOW_HEIGHT)
        }else {
            return CGFloat(TABLE_CELL_HEIGHT)
        }
    }
    
    //配置tableView 的单元格
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell
        if  indexPath.section==0 && indexPath.row == 0 {
            //如果是第一行,就需要构建热门条目
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.clearColor()
            cell.contentView.backgroundColor = UIColor.clearColor()
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.clipsToBounds = true
            
            let slideRect = CGRect(origin:CGPoint(x:0,y:0),size:CGSize(width:tableView.frame.width,height:CGFloat(IMAGE_HEIGHT)))
            let slideView = SlideScrollView(frame: slideRect)

            let todayNews = newsListControl.todayNews
            if let _todayNews = todayNews {
                let topNews = _todayNews.topNews
                
                slideView.initWithFrameRect(slideRect, topNewsArray: topNews)
                slideView.delegate = self
            }
            
            cell.addSubview(slideView)
            
            return cell
        }else{
            let tmp = tableView.dequeueReusableCellWithIdentifier("newsListTableViewCell")
            
            if  tmp == nil {
                cell = NewsListTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "newsListTableViewCell")
            }else {
                cell = tmp!
            }
            
//            let c = cell as! NewsListTableViewCell
            
            if  indexPath.section==0{
                //这个是今天的新闻
                
                let newsList = newsListControl.todayNews!
                
                cell = self.doReturnCell(newsList, row: indexPath.row-1)
                
            }else {
                let newsList = newsListControl.news[indexPath.section-1]
                
                cell = self.doReturnCell(newsList, row: indexPath.row)
                
            }
            
            return cell
        }
        
    }
    
    /**
    返回视图Cell
    
    - parameter newsList:
    - parameter row:
    
    - returns:
    */
    private func doReturnCell(newsList:NewsListVO,row:Int) -> UITableViewCell {
        
        let cell = mainTableView.dequeueReusableCellWithIdentifier("newsListTableViewCell") as! NewsListTableViewCell
        
        if let news = newsList.news {
            cell.titleLabel.text = news[row].title
            
            if  news[row].alreadyRead {
                cell.titleLabel.textColor = UIColor.grayColor()
            }else {
                cell.titleLabel.textColor = UIColor.blackColor()
            }
            
            let images = news[row].images
            if  let _img = images {
                cell.newsImageView.hnk_setImageFromURL(NSURL(string: _img[0] ?? "")!,placeholder: UIImage(named: "Image_Preview"))
            }
            cell.multipicLabel.hidden = !news[row].multipic
        }
        
        return cell
    }
    
    //================UITableViewDataSource的实现================================
    
    // MARK: UITableViewDelegate的实现
    //================UITableViewDelegate的实现==================================
    
    /**
    返回有多少个Sections
    
    - parameter tableView:
    
    - returns:
    */
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        let newsCount = self.newsListControl.news.count
        
        return newsCount+1
    }
    
    /**
    返回每一个Sections的Ttitle的高度
    
    - parameter tableView:
    - parameter section:   section的序号, 从0开始
    
    - returns:
    */
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if  section == 0 {
            //由于第一个section是不要的,所以直接设置高度为0
            return 0
        }
        
        return CGFloat(SECTION_HEIGHT)
    }
    
    /**
    设置每一个Section的样子
    
    - parameter tableView:
    - parameter section:
    
    - returns: 自定义的View
    */
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        //自定义一个View
        let myView = UIView()
        
        myView.backgroundColor = BACKGROUND_COLOR
        
        //实例化一个标签
        let titleView = UILabel(frame:CGRectMake(0, 0, tableView.frame.width, CGFloat(SECTION_HEIGHT)))
        
        titleView.font = UIFont.boldSystemFontOfSize(14)        //设置字体
        titleView.textAlignment = NSTextAlignment.Center        //设置居中
        titleView.textColor = UIColor.whiteColor()      //设置字体颜色
        
        //设置文字内容
        
        var news:NewsListVO
        if  section == 0 {
            news = self.newsListControl.todayNews!
        }else {
            news = self.newsListControl.news[section-1]
        }
        let date = news.date
        let formatter:NSDateFormatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "zh_CN")
        formatter.dateFormat = "yyyyMMdd"
        let today = formatter.dateFromString("\(date)")
        formatter.dateFormat = "MM月d日 cccc"
        
        titleView.text = formatter.stringFromDate(today!)
        
        myView.addSubview(titleView)
        
        return myView
    }
    
    // 当点击选择Row了以后的 动作
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        doAlreadyRead(indexPath)
        
        check3DTouch()
        
        //这个地方开始异步的获取新闻详细.然后再进行跳转
        self.performSegueWithIdentifier("pushSegue", sender: indexPath)
        
    }
    
    /**
    标记 已点击的 单元格
    
    - parameter newsListVO:
    - parameter indexPath:
    */
    private func doAlreadyRead(indexPath:NSIndexPath) {
        
        let cell = mainTableView.cellForRowAtIndexPath(indexPath)
        
        let c = cell as! NewsListTableViewCell
        
        c.titleLabel.textColor = UIColor.grayColor()
        
    }
    
    //================UITableViewDelegate的实现==================================
    

    // MARK: RefreshControlDelegate的实现
    //================RefreshControlDelegate的实现===============================
    func refreshControl(refreshControl: RefreshControl, didEngageRefreshDirection direction: RefreshDirection) {
        
        if  direction == RefreshDirection.RefreshDirectionTop {
            //是下拉刷新
            self.newsListControl.refreshNews()
            self.mainTableView.reloadData()
        }else{
            self.newsListControl.loadNewDayNews({ () -> Void in
                self.mainTableView.reloadData()
            })
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(1.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            refreshControl.finishRefreshingDirection(direction)
        })
        
    }
    
    //================RefreshControlDelegate的实现===============================
    
    // MARK: SlideScrollViewDelegate的实现
    //================SlideScrollViewDelegate的实现===============================
    func SlideScrollViewDidClicked(index: Int) {
        
        ///用于处理最热新闻的 点击, 使用遍历,把已加载的新闻找出来对比ID是否相同. 然后获取到她在表格中的坐标,从而进行页面跳转
        if  let topNews=newsListControl.todayNews?.topNews {
            let news = topNews[index-1]
            
            var indexPath:NSIndexPath?
            
            if  let n = newsListControl.todayNews?.news {
                for i in 0  ..< n.count  {
                    if news.id==n[i].id {
                        indexPath = NSIndexPath(forRow: i+1, inSection: 0)
                        //这个地方开始异步的获取新闻详细.然后再进行跳转
                        self.performSegueWithIdentifier("pushSegue", sender: indexPath)
                        return
                    }
                }
            }
            
            gotoTopNewsDetail(news, block: { (indexPath) -> Void in
                //这个地方开始异步的获取新闻详细.然后再进行跳转
                self.performSegueWithIdentifier("pushSegue", sender: indexPath)
                self.mainTableView.reloadData()
            })
        }
    }
    
    /// 对于比在已加载新闻的 最热新闻. 需要加载今天以前的新闻来做对比. 又由于这个加载的过程是异步的.因此,这个地方做了一个递归
    private func gotoTopNewsDetail(news:NewsVO,block:(NSIndexPath)->Void){
        
        let nes = newsListControl.news
        
        for j in 0 ..< nes.count {
            let nList = nes[j]
            let n = nList.news!
            
            for i in 0  ..< n.count  {
                if news.id==n[i].id {
                    block(NSIndexPath(forRow: i, inSection: j+1))
                    return
                }
            }
        }
        
        /// 加载上一天的新闻
        newsListControl.loadNewDayNews({ () -> Void in
            /// 加载成功后,重新的找这篇新闻是否是在已加载了的新闻中
            self.gotoTopNewsDetail(news, block: block)
        })
    }
    
    //================SlideScrollViewDelegate的实现===============================

    // MARK: 3D Touch UIViewControllerPreviewingDelegate的实现
    
    /**
    检测页面是否处于3DTouch
    */
    func check3DTouch(){
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            
            self.registerForPreviewingWithDelegate(self, sourceView: self.view)
            //长按停止
            self.longPress.enabled = false
            
        } else {
            self.longPress.enabled = true
        }
    }
    
    /**
    轻按进入浮动页面
    
    - parameter previewingContext:
    - parameter location:
    
    - returns:
    */
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let cellPosition = mainTableView.convertPoint(location, fromView: view)
        
        if let touchedIndexPath = mainTableView.indexPathForRowAtPoint(cellPosition) {
            
            mainTableView.deselectRowAtIndexPath(touchedIndexPath, animated: true)
            
            let aStoryboard = UIStoryboard(name: "Main", bundle:NSBundle.mainBundle())
            
            if let newsDetailViewController = aStoryboard.instantiateViewControllerWithIdentifier("newsDetailViewController") as? NewsDetailViewController  {
                
                if  newsDetailViewController.newsListControl == nil {
                    newsDetailViewController.newsListControl = self.newsListControl
                    newsDetailViewController.mainViewController = self
                }
                
                newsDetailViewController.newsLocation = (touchedIndexPath.section,touchedIndexPath.row)
                
                let cellFrame = mainTableView.cellForRowAtIndexPath(touchedIndexPath)!.frame
                previewingContext.sourceRect = view.convertRect(cellFrame, fromView: mainTableView)
                
                return newsDetailViewController
            }
        }

        
        
        return UIViewController()
    }
    
    /**
    重按进入文章详情页
    
    - parameter previewingContext:
    - parameter viewControllerToCommit:
    */
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        self.showViewController(viewControllerToCommit, sender: self)
    }
    
}

