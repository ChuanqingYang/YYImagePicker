
import SwiftUI
import PhotosUI

// MARK: - Asset Model
public struct ImageAsset: Identifiable {
    public var id:String = UUID().uuidString
    public var asset:PHAsset
    public var thumbnail:UIImage?
    // select image index
    public var assetIndex:Int = -1
}

// MARK: - ImagePickerView
@available(iOS 15.0, *)
public struct PopupImagePickerView: View {
    
    @StateObject public var vm:PopupImagePickerViewModel = .init()
    
    @Environment(\.self) public var env
    // Callbacks
    public var onEnd:()->()
    public var onSelected:([PHAsset])->()
    
    public var body: some View {
        let screenSize = UIScreen.main.bounds.size
        VStack(spacing: 0) {
            HStack {
                Text("Select Images")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    onEnd()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.primary)
                        .font(.title3)
                }
            }
            .padding([.horizontal,.top])
            .padding(.bottom,10)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(),spacing: 10), count: 4),spacing: 12) {
                    // MARK: - $ sign make it to be assigned
                    ForEach($vm.fetchedImages) { $image in
                        GridImageItem(imageAsset: image)
                            .onAppear {
                                // fetch thumb image
                                if image.thumbnail == nil {
                                    let manager = PHCachingImageManager.default()
                                    manager.requestImage(for: image.asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil) { uiImage, _ in
                                        image.thumbnail = uiImage
                                    }
                                }
                            }
                    }
                }.padding()
            }
            .safeAreaInset(edge: .bottom, alignment: .center) {
                Button {
                    let imageAsset = vm.selectedImages.compactMap { imageAsset -> PHAsset? in
                        return imageAsset.asset
                    }
                    onSelected(imageAsset)
                } label: {
                    Text("Add\(vm.selectedImages.isEmpty ? "" : "\(vm.selectedImages.count)")Images")
                        .foregroundColor(.white)
                        .font(.callout).fontWeight(.semibold)
                        .padding(.horizontal,30)
                        .padding(.vertical,10)
                        .background {
                            Capsule()
                                .fill(.blue)
                        }
                }
                .disabled(vm.selectedImages.isEmpty)
                .opacity(vm.selectedImages.isEmpty ? 0.6 : 1)
                .padding(.vertical)

            }
        }
        .frame(height: screenSize.height / 1.8)
        .frame(maxWidth: screenSize.width - 40 > 350 ? 350 : screenSize.width)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(env.colorScheme == .dark ? .black : .white)
        }
        .frame(width: screenSize.width, height: screenSize.height,alignment: .center)
    }
    
    @ViewBuilder
    func GridImageItem(imageAsset:ImageAsset) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if let image = imageAsset.thumbnail {
                    Image(uiImage: image)
                        .resizable().aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }else {
                    ProgressView()
                        .frame(width: size.width, height: size.height, alignment: .center)
                }
                
                // check
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.black.opacity(0.1))
                    
                    Circle()
                        .fill(.white.opacity(0.25))
                    
                    Circle()
                        .stroke(.white,lineWidth: 1)
                    
                    // checked ui
                    if let index = vm.selectedImages.firstIndex(where: { asset in
                        asset.id == imageAsset.id
                    }) {
                        Circle()
                            .fill(.blue)
                        
                        Text("\(vm.selectedImages[index].assetIndex + 1)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 20, height: 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(5)
            }
            .clipped()
            .onTapGesture {
                withAnimation(.easeInOut) {
                    // add or remove image
                    if let index = vm.selectedImages.firstIndex(where: { asset in
                        asset.id == imageAsset.id
                    }) {
                        // remove and update
                        vm.selectedImages.remove(at: index)
                        vm.selectedImages.enumerated().forEach { item in
                            vm.selectedImages[item.offset].assetIndex = item.offset
                        }
                    }else {
                        // add new
                        var newAsset = imageAsset
                        newAsset.assetIndex = vm.selectedImages.count
                        vm.selectedImages.append(newAsset)
                    }
                }
            }
        }
        .frame(height: 70)
    }
}

// MARK: - View Extension
@available(iOS 15.0, *)
extension View {
    @ViewBuilder
    public func popupImagePickerView(show:Binding<Bool>,transition:AnyTransition = .move(edge: .bottom),onSelect:@escaping([PHAsset])->()) -> some View {
        self
            .overlay {
                let screenSize = UIScreen.main.bounds.size
                ZStack {
                    // bg
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .opacity(show.wrappedValue ? 1 : 0)
                        .onTapGesture {
                            show.wrappedValue = false
                        }
                    
                    if show.wrappedValue {
                        PopupImagePickerView {
                            show.wrappedValue = false
                        } onSelected: { assets in
                            onSelect(assets)
                            show.wrappedValue = false
                        }
                        .transition(transition)
                    }
                }
                .frame(width: screenSize.width, height: screenSize.height)
                .animation(.easeInOut, value: show.wrappedValue)
            }
    }
}

// MARK: - ViewModel
@available(iOS 15.0, *)
public class PopupImagePickerViewModel: ObservableObject {
    @Published public var fetchedImages:[ImageAsset] = []
    @Published public var selectedImages:[ImageAsset] = []
    
    public init() {
        self.fetchImages()
    }
    
    public func fetchImages() {
        
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.includeAssetSourceTypes = [.typeUserLibrary]
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        PHAsset.fetchAssets(with: .image, options: options).enumerateObjects { asset, _, _ in
            let imageAsset: ImageAsset = .init(asset: asset)
            self.fetchedImages.append(imageAsset)
        }
    }
    
    public static func handle(assets:[PHAsset],completion:@escaping ([UIImage])->()) {
        
        var images:[UIImage] = []
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        DispatchQueue.global(qos: .userInteractive).async {
            assets.forEach { asset in
                let manager = PHCachingImageManager.default()
                manager.requestImage(for: asset, targetSize: .init(), contentMode: .aspectFit, options: options) { uiImage, _ in
                    guard let image = uiImage else { return }
                    images.append(image)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(images)
        }
    }
}


