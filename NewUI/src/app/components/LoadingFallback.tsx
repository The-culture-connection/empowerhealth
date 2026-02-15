export function LoadingFallback() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] flex items-center justify-center">
      <div className="text-center">
        <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#663399] to-[#8855bb] flex items-center justify-center mx-auto mb-4 animate-pulse">
          <span className="text-2xl text-white">🤰</span>
        </div>
        <p className="text-gray-600">Loading...</p>
      </div>
    </div>
  );
}
