export function calculateTrimester(dueDate: Date | null | undefined): string {
  if (!dueDate) return 'First';
  
  const now = new Date();
  const daysUntilDue = Math.floor((dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  const weeksPregnant = 40 - Math.floor(daysUntilDue / 7);
  
  if (weeksPregnant <= 0) return 'First';
  if (weeksPregnant <= 13) return 'First';
  if (weeksPregnant <= 27) return 'Second';
  return 'Third';
}

export function calculateWeeksPregnant(dueDate: Date | null | undefined): number {
  if (!dueDate) return 0;
  
  const now = new Date();
  const daysUntilDue = Math.floor((dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  const weeksPregnant = 40 - Math.floor(daysUntilDue / 7);
  
  return weeksPregnant > 0 ? weeksPregnant : 0;
}

export function getTrimesterInfo(trimester: string): string {
  switch (trimester) {
    case 'First':
      return 'Weeks 1-13';
    case 'Second':
      return 'Weeks 14-27';
    case 'Third':
      return 'Weeks 28-40';
    default:
      return '';
  }
}

export function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
