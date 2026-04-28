// Add this new struct


import SwiftUI

struct PagerView<Content: View>: View {
    let pageCount: Int
    @Binding var currentIndex: Int
    let content: Content
    
    init(pageCount: Int, currentIndex: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.pageCount = pageCount
        self._currentIndex = currentIndex
        self.content = content()
    }
    
    @GestureState private var translation: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                self.content
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
            .offset(x: -CGFloat(self.currentIndex) * geometry.size.width)
            .offset(x: self.translation)
            .clipped() // Prevent white space from showing
            .animation(.interactiveSpring(), value: currentIndex)
            .animation(.interactiveSpring(), value: translation)
            .gesture(
                DragGesture()
                    .updating(self.$translation) { value, state, _ in
                        if value.translation.width < 0 {  // Forward swipe (left drag)
                            if self.currentIndex < self.pageCount - 1 {
                                state = value.translation.width
                            } else {
                                state = 0  // Clamp to prevent movement/white space on last page
                            }
                        } else {
                            // Prevent backward swipe beyond first page
                            if self.currentIndex > 0 {
                                state = value.translation.width
                            } else {
                                state = 0
                            }
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < 0 && self.currentIndex < self.pageCount - 1 {
                            let offset = value.translation.width / geometry.size.width
                            let newIndex = (CGFloat(self.currentIndex) - offset).rounded()
                            self.currentIndex = min(max(Int(newIndex), 0), self.pageCount - 1)
                        } else if value.translation.width > 0 && self.currentIndex > 0 {
                            let offset = value.translation.width / geometry.size.width
                            let newIndex = (CGFloat(self.currentIndex) - offset).rounded()
                            self.currentIndex = min(max(Int(newIndex), 0), self.pageCount - 1)
                        }
                    }
            )
        }
        .ignoresSafeArea(.all)
    }
}
// PageControllerView (replace TabView with PagerView)
struct PageControllerView: View {
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Background color to prevent white space
            Color.black
                .ignoresSafeArea(.all)
            
            PagerView(pageCount: 3, currentIndex: $currentPage) {
                OnboardingFirstVC(currentPage: $currentPage)
                OnboardingSecondVC(currentPage: $currentPage)
                OnboardingThirdVC()
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

